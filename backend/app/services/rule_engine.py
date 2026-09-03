import re
import difflib
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from app.models.schemas import (
    Requirement,
    Evidence,
    RuleEvaluationResult,
    StatusEnum,
    ReasonCodeEnum,
    RuleTypeEnum,
)


def normalize_text(text: str, normalizations: Optional[List[str]] = None) -> str:
    if not text:
        return ""
    res = str(text)
    if not normalizations:
        normalizations = ["casefold", "remove_punctuation", "collapse_spaces"]

    for norm in normalizations:
        if norm == "casefold":
            res = res.lower()
        elif norm == "remove_punctuation":
            res = re.sub(r"[^\w\s]", "", res)
        elif norm == "collapse_spaces":
            res = re.sub(r"\s+", " ", res).strip()
    return res


def compute_string_similarity(a: str, b: str) -> float:
    na = normalize_text(a)
    nb = normalize_text(b)
    if not na or not nb:
        return 0.0
    if na == nb:
        return 1.0
    return difflib.SequenceMatcher(None, na, nb).ratio()


class DeterministicRuleEngine:
    ENGINE_VERSION = "1.0.0"

    @classmethod
    def evaluate(
        cls,
        requirement: Requirement,
        evidence_list: List[Evidence],
        context: Optional[Dict[str, Any]] = None,
    ) -> RuleEvaluationResult:
        context = context or {}
        rule = requirement.rule
        rule_version = f"{requirement.requirement_id}:v{requirement.version}"
        timestamp = datetime.now(timezone.utc).isoformat()
        result_id = f"RES-{requirement.requirement_id}-{int(datetime.now(timezone.utc).timestamp())}"

        # Filter evidence matching expected document types
        matching_evidence = [
            e for e in evidence_list
            if not requirement.expected_document_types or e.document_type in requirement.expected_document_types
        ]

        # 1. Missing evidence check
        if not matching_evidence:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.FAIL if rule.mandatory else StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[],
                evaluated_values={},
                explanation=f"No supporting document submitted for {requirement.title}. Mandatory requirement.",
                plain_language_bidder_msg=f"Please upload {requirement.title} ({', '.join(requirement.expected_document_types)}).",
                reason_codes=[ReasonCodeEnum.MISSING_EVIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        # 2. Check for low confidence or processing errors
        active_evidences = [e for e in matching_evidence if e.status == "ACTIVE"]
        if not active_evidences:
            active_evidences = matching_evidence

        low_conf_ev = [e for e in active_evidences if e.confidence < 0.70]
        if low_conf_ev:
            ev = low_conf_ev[0]
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[e.evidence_id for e in active_evidences],
                evaluated_values={"ocr_confidence": ev.confidence},
                explanation=f"OCR quality is low (confidence {int(ev.confidence * 100)}%) on {ev.file_name}. Requires human verification.",
                plain_language_bidder_msg="Document scan quality is low. Review pending or upload a clearer scan.",
                reason_codes=[ReasonCodeEnum.LOW_CONFIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        # 3. Rule type dispatch
        if rule.type == RuleTypeEnum.REQUIRED_DOCUMENT:
            return cls._eval_required_document(requirement, active_evidences, rule_version, result_id, timestamp)

        elif rule.type == RuleTypeEnum.NUMERIC_THRESHOLD:
            return cls._eval_numeric_threshold(requirement, active_evidences, rule_version, result_id, timestamp)

        elif rule.type == RuleTypeEnum.DATE_VALIDITY:
            return cls._eval_date_validity(requirement, active_evidences, rule_version, result_id, timestamp, context)

        elif rule.type == RuleTypeEnum.CROSS_DOCUMENT_MATCH:
            return cls._eval_cross_document_match(requirement, active_evidences, rule_version, result_id, timestamp, context)

        elif rule.type == RuleTypeEnum.BOOLEAN_DECLARATION:
            return cls._eval_boolean_declaration(requirement, active_evidences, rule_version, result_id, timestamp)

        elif rule.type == RuleTypeEnum.TEXT_MATCH:
            return cls._eval_text_match(requirement, active_evidences, rule_version, result_id, timestamp)

        else:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[e.evidence_id for e in active_evidences],
                evaluated_values={},
                explanation=f"Rule type '{rule.type}' is unsupported or requires custom officer review.",
                plain_language_bidder_msg="Requirement requires special officer validation.",
                reason_codes=[ReasonCodeEnum.UNSUPPORTED_RULE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

    @classmethod
    def _eval_required_document(cls, requirement, evidences, rule_version, result_id, timestamp):
        ev = evidences[0]
        status_val = ev.fields.get("status", None)
        status_str = status_val.extracted_value if status_val else "ACTIVE"

        if status_str in ["INACTIVE", "CANCELLED", "SUSPENDED"]:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.FAIL,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={"document_status": status_str},
                explanation=f"{ev.document_type} is marked as {status_str} in official registry.",
                plain_language_bidder_msg=f"{requirement.title} failed: Certificate is {status_str}.",
                reason_codes=[ReasonCodeEnum.IDENTITY_MISMATCH],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        return RuleEvaluationResult(
            result_id=result_id,
            requirement_id=requirement.requirement_id,
            status=StatusEnum.PASS,
            rule_version=rule_version,
            evidence_ids=[ev.evidence_id],
            evaluated_values={"document_type": ev.document_type, "file_name": ev.file_name},
            explanation=f"Valid {ev.document_type} successfully verified against registry.",
            plain_language_bidder_msg=f"{requirement.title} verified and accepted.",
            reason_codes=[],
            engine_version=cls.ENGINE_VERSION,
            timestamp=timestamp,
        )

    @classmethod
    def _eval_numeric_threshold(cls, requirement, evidences, rule_version, result_id, timestamp):
        rule = requirement.rule
        target_field = rule.field or "average_annual_turnover"
        operator = rule.operator or ">="
        threshold = float(rule.value) if rule.value is not None else 0.0

        # Extract values across evidence
        found_values = []
        source_pages = []
        for ev in evidences:
            if target_field in ev.fields:
                f = ev.fields[target_field]
                try:
                    val = float(f.extracted_value)
                    found_values.append((val, ev, f.source_page))
                    source_pages.append(f.source_page)
                except (ValueError, TypeError):
                    pass

        if not found_values:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[e.evidence_id for e in evidences],
                evaluated_values={},
                explanation=f"Could not extract numeric field '{target_field}' from uploaded document.",
                plain_language_bidder_msg="Turnover figures could not be automatically extracted. Routed to Officer Review.",
                reason_codes=[ReasonCodeEnum.LOW_CONFIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        # Check for conflicting figures across multiple uploaded pages/docs
        extracted_nums = [v[0] for v in found_values]
        if len(set(extracted_nums)) > 1:
            # Multiple differing values found!
            val_strs = [f"₹{v:,.2f}" for v in set(extracted_nums)]
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[v[1].evidence_id for v in found_values],
                evaluated_values={"conflicting_values": extracted_nums, "threshold": threshold},
                explanation=f"Conflicting turnover values detected ({', '.join(val_strs)}). Requires officer verification.",
                plain_language_bidder_msg="Turnover evidence shows conflicting figures across pages. Under Officer Review.",
                reason_codes=[ReasonCodeEnum.CONFLICTING_EVIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        actual_val, ev, page = found_values[0]
        evaluated_vals = {target_field: actual_val, "threshold": threshold, "source_page": page}

        # Format Indian Rupee currency display (lakh/crore)
        def fmt_inr(val):
            if val >= 10000000:
                return f"₹{val/10000000:.2f} Crore"
            elif val >= 100000:
                return f"₹{val/100000:.2f} Lakh"
            return f"₹{val:,.2f}"

        passes = False
        if operator == ">=" and actual_val >= threshold:
            passes = True
        elif operator == ">" and actual_val > threshold:
            passes = True
        elif operator == "<=" and actual_val <= threshold:
            passes = True
        elif operator == "==" and actual_val == threshold:
            passes = True

        if passes:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.PASS,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values=evaluated_vals,
                explanation=f"Extracted {target_field} of {fmt_inr(actual_val)} satisfies required threshold of {fmt_inr(threshold)} (Page {page}).",
                plain_language_bidder_msg=f"Turnover verified: {fmt_inr(actual_val)} exceeds required {fmt_inr(threshold)}.",
                reason_codes=[],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )
        else:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.FAIL,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values=evaluated_vals,
                explanation=f"Extracted {target_field} of {fmt_inr(actual_val)} is below mandatory threshold {fmt_inr(threshold)}.",
                plain_language_bidder_msg=f"Turnover {fmt_inr(actual_val)} is below the mandatory requirement of {fmt_inr(threshold)}.",
                reason_codes=[ReasonCodeEnum.BELOW_THRESHOLD],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

    @classmethod
    def _eval_date_validity(cls, requirement, evidences, rule_version, result_id, timestamp, context):
        rule = requirement.rule
        target_field = rule.field or "expiry_date"
        ref_date_str = context.get("submission_date") or datetime.utcnow().strftime("%Y-%m-%d")

        ev = evidences[0]
        if target_field not in ev.fields:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={},
                explanation=f"Validity date '{target_field}' not found in document.",
                plain_language_bidder_msg="Certificate validity date unclear. Routed for review.",
                reason_codes=[ReasonCodeEnum.LOW_CONFIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        exp_str = str(ev.fields[target_field].extracted_value)
        try:
            exp_date = datetime.strptime(exp_str, "%Y-%m-%d")
            ref_date = datetime.strptime(ref_date_str, "%Y-%m-%d")

            if exp_date >= ref_date:
                return RuleEvaluationResult(
                    result_id=result_id,
                    requirement_id=requirement.requirement_id,
                    status=StatusEnum.PASS,
                    rule_version=rule_version,
                    evidence_ids=[ev.evidence_id],
                    evaluated_values={"expiry_date": exp_str, "reference_date": ref_date_str},
                    explanation=f"Document valid until {exp_str}, which meets the deadline {ref_date_str}.",
                    plain_language_bidder_msg=f"Certificate validity verified (Valid till {exp_str}).",
                    reason_codes=[],
                    engine_version=cls.ENGINE_VERSION,
                    timestamp=timestamp,
                )
            else:
                return RuleEvaluationResult(
                    result_id=result_id,
                    requirement_id=requirement.requirement_id,
                    status=StatusEnum.FAIL,
                    rule_version=rule_version,
                    evidence_ids=[ev.evidence_id],
                    evaluated_values={"expiry_date": exp_str, "reference_date": ref_date_str},
                    explanation=f"Certificate expired on {exp_str} prior to tender deadline {ref_date_str}.",
                    plain_language_bidder_msg=f"Certificate expired on {exp_str}. Please upload an active certificate.",
                    reason_codes=[ReasonCodeEnum.EXPIRED],
                    engine_version=cls.ENGINE_VERSION,
                    timestamp=timestamp,
                )
        except Exception:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={"raw_expiry": exp_str},
                explanation=f"Could not parse expiry date format '{exp_str}'.",
                plain_language_bidder_msg="Date format unclear. Routed to Officer Review.",
                reason_codes=[ReasonCodeEnum.LOW_CONFIDENCE],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

    @classmethod
    def _eval_cross_document_match(cls, requirement, evidences, rule_version, result_id, timestamp, context):
        rule = requirement.rule
        left_field_name = rule.left.get("field", "legal_name") if rule.left else "legal_name"
        right_source = rule.right.get("source", "COMPANY_PROFILE") if rule.right else "COMPANY_PROFILE"
        right_field_name = rule.right.get("field", "legal_name") if rule.right else "legal_name"
        min_sim = rule.allowed_similarity or 0.90

        ev = evidences[0]
        left_val = ev.fields.get(left_field_name)
        left_str = left_val.extracted_value if left_val else ""

        # Retrieve reference value from context or company profile
        right_str = context.get(right_field_name) or context.get("bidder_company_name") or ""

        sim = compute_string_similarity(str(left_str), str(right_str))
        evaluated_vals = {"extracted": left_str, "reference": right_str, "similarity": round(sim, 3)}

        if sim >= min_sim:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.PASS,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values=evaluated_vals,
                explanation=f"Entity name '{left_str}' matched profile '{right_str}' ({int(sim * 100)}% match).",
                plain_language_bidder_msg="Entity identity verified against registration.",
                reason_codes=[],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )
        elif sim >= 0.70:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values=evaluated_vals,
                explanation=f"Partial match between '{left_str}' and '{right_str}' ({int(sim * 100)}%). Verification required.",
                plain_language_bidder_msg="Minor name discrepancy detected. Under officer review.",
                reason_codes=[ReasonCodeEnum.IDENTITY_MISMATCH],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )
        else:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.FAIL,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values=evaluated_vals,
                explanation=f"Entity mismatch: '{left_str}' does not match bidder company '{right_str}'.",
                plain_language_bidder_msg="Document entity name does not match bidder profile.",
                reason_codes=[ReasonCodeEnum.IDENTITY_MISMATCH],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

    @classmethod
    def _eval_boolean_declaration(cls, requirement, evidences, rule_version, result_id, timestamp):
        ev = evidences[0]
        signed = ev.fields.get("signed") or ev.fields.get("compliance_confirmed")
        val = str(signed.extracted_value).lower() if signed else ""

        if val in ["true", "yes", "confirmed", "signed"]:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.PASS,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={"signed": True},
                explanation="Mandatory declaration signed and verified.",
                plain_language_bidder_msg="Technical declaration confirmed.",
                reason_codes=[],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )
        else:
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.FAIL,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={"signed": False},
                explanation="Technical declaration is missing signature or explicit confirmation.",
                plain_language_bidder_msg="Declaration is unsigned. Please upload signed document.",
                reason_codes=[ReasonCodeEnum.BELOW_THRESHOLD],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

    @classmethod
    def _eval_text_match(cls, requirement, evidences, rule_version, result_id, timestamp):
        rule = requirement.rule
        ev = evidences[0]
        field_val = ev.fields.get(rule.field or "authorization_scope")
        val_str = str(field_val.extracted_value) if field_val else ""

        # Check if bid number is included or authorization is specific
        if "general" in val_str.lower() and "gem" not in val_str.lower():
            return RuleEvaluationResult(
                result_id=result_id,
                requirement_id=requirement.requirement_id,
                status=StatusEnum.REVIEW,
                rule_version=rule_version,
                evidence_ids=[ev.evidence_id],
                evaluated_values={"scope": val_str},
                explanation="OEM authorization is generic and does not explicitly cite this GeM tender bid number.",
                plain_language_bidder_msg="OEM authorization scope is broad. Routed to Officer Review.",
                reason_codes=[ReasonCodeEnum.UNSPECIFIED_BID_NUMBER],
                engine_version=cls.ENGINE_VERSION,
                timestamp=timestamp,
            )

        return RuleEvaluationResult(
            result_id=result_id,
            requirement_id=requirement.requirement_id,
            status=StatusEnum.PASS,
            rule_version=rule_version,
            evidence_ids=[ev.evidence_id],
            evaluated_values={"scope": val_str},
            explanation="OEM authorization explicitly verified for this procurement.",
            plain_language_bidder_msg="OEM authorization verified.",
            reason_codes=[],
            engine_version=cls.ENGINE_VERSION,
            timestamp=timestamp,
        )
