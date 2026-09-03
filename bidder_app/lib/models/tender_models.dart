class RequirementModel {
  final String requirementId;
  final String tenderId;
  final String clauseReference;
  final String title;
  final String description;
  final String requirementType;
  final bool mandatory;
  final List<String> expectedDocumentTypes;
  final double aiConfidence;
  final bool officerVerified;
  final int version;

  RequirementModel({
    required this.requirementId,
    required this.tenderId,
    required this.clauseReference,
    required this.title,
    required this.description,
    required this.requirementType,
    required this.mandatory,
    required this.expectedDocumentTypes,
    required this.aiConfidence,
    required this.officerVerified,
    this.version = 1,
  });

  factory RequirementModel.fromJson(Map<String, dynamic> json) {
    return RequirementModel(
      requirementId: json['requirement_id'] ?? '',
      tenderId: json['tender_id'] ?? '',
      clauseReference: json['clause_reference'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requirementType: json['requirement_type'] ?? '',
      mandatory: json['mandatory'] ?? true,
      expectedDocumentTypes: List<String>.from(json['expected_document_types'] ?? []),
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble() ?? 0.95,
      officerVerified: json['officer_verified'] ?? false,
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'requirement_id': requirementId,
    'tender_id': tenderId,
    'clause_reference': clauseReference,
    'title': title,
    'description': description,
    'requirement_type': requirementType,
    'mandatory': mandatory,
    'expected_document_types': expectedDocumentTypes,
    'ai_confidence': aiConfidence,
    'officer_verified': officerVerified,
    'version': version,
  };
}

class TenderModel {
  final String tenderId;
  final String bidNumber;
  final String title;
  final String organization;
  final String ministry;
  final String department;
  final String category;
  final String itemDescription;
  final double quantity;
  final String unit;
  final double? estimatedValue;
  final String issueDate;
  final String submissionDeadline;
  final String bidEndDate;
  final String bidEndTime;
  final String bidOpeningDate;
  final String deliveryPeriod;
  final String placeOfDelivery;
  final double emdAmount;
  final bool emdRequired;
  final String performanceSecurity;
  final String bidValidity;
  final String eligibilityCriteria;
  final String technicalRequirements;
  final String financialRequirements;
  final String turnoverRequirement;
  final String experienceRequirement;
  final bool oemAuthorizationRequirement;
  final String msePreference;
  final String makeInIndiaPreference;
  final bool gstRequired;
  final bool panRequired;
  final bool udyamRequired;
  final String contactInformation;
  final String extractionStatus;
  final String extractionSource;
  final String extractedAt;
  final String? extractionError;
  final String status;
  final String ruleSetVersion;
  final String? originalFileId;
  final String? driveFolderId;
  final String? fileName;
  final List<RequirementModel> requirements;

  TenderModel({
    required this.tenderId,
    required this.bidNumber,
    required this.title,
    required this.organization,
    this.ministry = '',
    this.department = '',
    this.category = 'Government Tender',
    this.itemDescription = '',
    this.quantity = 1.0,
    this.unit = 'Units',
    this.estimatedValue,
    required this.issueDate,
    required this.submissionDeadline,
    this.bidEndDate = '',
    this.bidEndTime = '',
    this.bidOpeningDate = '',
    this.deliveryPeriod = '30 Days',
    this.placeOfDelivery = '',
    this.emdAmount = 0.0,
    this.emdRequired = false,
    this.performanceSecurity = 'Not Required',
    this.bidValidity = '180 Days',
    this.eligibilityCriteria = '',
    this.technicalRequirements = '',
    this.financialRequirements = '',
    this.turnoverRequirement = '',
    this.experienceRequirement = '',
    this.oemAuthorizationRequirement = false,
    this.msePreference = 'Not Specified',
    this.makeInIndiaPreference = 'Not Specified',
    this.gstRequired = true,
    this.panRequired = true,
    this.udyamRequired = false,
    this.contactInformation = '',
    this.extractionStatus = 'COMPLETED',
    this.extractionSource = 'PYMUPDF_GEM_PARSER',
    this.extractedAt = '',
    this.extractionError,
    required this.status,
    required this.ruleSetVersion,
    this.originalFileId,
    this.driveFolderId,
    this.fileName,
    required this.requirements,
  });

  factory TenderModel.fromJson(Map<String, dynamic> json) {
    var reqList = (json['requirements'] as List? ?? [])
        .map((r) => RequirementModel.fromJson(r))
        .toList();

    return TenderModel(
      tenderId: json['tender_id'] ?? json['tenderId'] ?? '',
      bidNumber: json['bid_number'] ?? json['bidNumber'] ?? '',
      title: json['title'] ?? '',
      organization: json['organization'] ?? '',
      ministry: json['ministry'] ?? '',
      department: json['department'] ?? '',
      category: json['category'] ?? 'Government Tender',
      itemDescription: json['item_description'] ?? json['itemDescription'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unit: json['unit'] ?? 'Units',
      estimatedValue: (json['estimated_value'] ?? json['estimatedValue'] as num?)?.toDouble(),
      issueDate: json['issue_date'] ?? json['issueDate'] ?? '',
      submissionDeadline: json['submission_deadline'] ?? json['submissionDeadline'] ?? '',
      bidEndDate: json['bid_end_date'] ?? json['bidEndDate'] ?? '',
      bidEndTime: json['bid_end_time'] ?? json['bidEndTime'] ?? '',
      bidOpeningDate: json['bid_opening_date'] ?? json['bidOpeningDate'] ?? '',
      deliveryPeriod: json['delivery_period'] ?? json['deliveryPeriod'] ?? '30 Days',
      placeOfDelivery: json['place_of_delivery'] ?? json['placeOfDelivery'] ?? '',
      emdAmount: (json['emd_amount'] ?? json['emdAmount'] as num?)?.toDouble() ?? 0.0,
      emdRequired: json['emd_required'] ?? json['emdRequired'] ?? false,
      performanceSecurity: json['performance_security'] ?? json['performanceSecurity'] ?? 'Not Required',
      bidValidity: json['bid_validity'] ?? json['bidValidity'] ?? '180 Days',
      eligibilityCriteria: json['eligibility_criteria'] ?? json['eligibilityCriteria'] ?? '',
      technicalRequirements: json['technical_requirements'] ?? json['technicalRequirements'] ?? '',
      financialRequirements: json['financial_requirements'] ?? json['financialRequirements'] ?? '',
      turnoverRequirement: json['turnover_requirement'] ?? json['turnoverRequirement'] ?? '',
      experienceRequirement: json['experience_requirement'] ?? json['experienceRequirement'] ?? '',
      oemAuthorizationRequirement: json['oem_authorization_requirement'] ?? json['oemAuthorizationRequirement'] ?? false,
      msePreference: json['mse_preference'] ?? json['msePreference'] ?? 'Not Specified',
      makeInIndiaPreference: json['make_in_india_preference'] ?? json['makeInIndiaPreference'] ?? 'Not Specified',
      gstRequired: json['gst_required'] ?? json['gstRequired'] ?? true,
      panRequired: json['pan_required'] ?? json['panRequired'] ?? true,
      udyamRequired: json['udyam_required'] ?? json['udyamRequired'] ?? false,
      contactInformation: json['contact_information'] ?? json['contactInformation'] ?? '',
      extractionStatus: json['extraction_status'] ?? json['extractionStatus'] ?? 'COMPLETED',
      extractionSource: json['extraction_source'] ?? json['extractionSource'] ?? 'PYMUPDF_GEM_PARSER',
      extractedAt: json['extracted_at'] ?? json['extractedAt'] ?? '',
      extractionError: json['extraction_error'] ?? json['extractionError'],
      status: json['status'] ?? 'PUBLISHED',
      ruleSetVersion: json['rule_set_version'] ?? json['ruleSetVersion'] ?? 'v1.0',
      originalFileId: json['original_file_id'] ?? json['originalFileId'] ?? json['source_drive_file_id'],
      driveFolderId: json['drive_folder_id'] ?? json['driveFolderId'],
      fileName: json['file_name'] ?? json['fileName'],
      requirements: reqList,
    );
  }

  Map<String, dynamic> toJson() => {
    'tender_id': tenderId,
    'bid_number': bidNumber,
    'title': title,
    'organization': organization,
    'ministry': ministry,
    'department': department,
    'category': category,
    'item_description': itemDescription,
    'quantity': quantity,
    'unit': unit,
    'estimated_value': estimatedValue,
    'issue_date': issueDate,
    'submission_deadline': submissionDeadline,
    'bid_end_date': bidEndDate,
    'bid_end_time': bidEndTime,
    'bid_opening_date': bidOpeningDate,
    'delivery_period': deliveryPeriod,
    'place_of_delivery': placeOfDelivery,
    'emd_amount': emdAmount,
    'emd_required': emdRequired,
    'performance_security': performanceSecurity,
    'bid_validity': bidValidity,
    'eligibility_criteria': eligibilityCriteria,
    'technical_requirements': technicalRequirements,
    'financial_requirements': financialRequirements,
    'turnover_requirement': turnoverRequirement,
    'experience_requirement': experienceRequirement,
    'oem_authorization_requirement': oemAuthorizationRequirement,
    'mse_preference': msePreference,
    'make_in_india_preference': makeInIndiaPreference,
    'gst_required': gstRequired,
    'pan_required': panRequired,
    'udyam_required': udyamRequired,
    'contact_information': contactInformation,
    'extraction_status': extractionStatus,
    'extraction_source': extractionSource,
    'extracted_at': extractedAt,
    'extraction_error': extractionError,
    'status': status,
    'rule_set_version': ruleSetVersion,
    'original_file_id': originalFileId,
    'drive_folder_id': driveFolderId,
    'file_name': fileName,
    'requirements': requirements.map((r) => r.toJson()).toList(),
  };
}

class EvidenceModel {
  final String evidenceId;
  final String applicationId;
  final String requirementId;
  final String documentType;
  final String fileName;
  final String driveFileId;
  final String sha256;
  final String uploadedBy;
  final String uploadedAt;
  final int version;
  final String status; // ACTIVE, SUPERSEDED
  final double confidence;

  EvidenceModel({
    required this.evidenceId,
    required this.applicationId,
    required this.requirementId,
    required this.documentType,
    required this.fileName,
    required this.driveFileId,
    required this.sha256,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.version,
    required this.status,
    this.confidence = 0.95,
  });

  factory EvidenceModel.fromJson(Map<String, dynamic> json) {
    return EvidenceModel(
      evidenceId: json['evidence_id'] ?? '',
      applicationId: json['application_id'] ?? '',
      requirementId: json['requirement_id'] ?? '',
      documentType: json['document_type'] ?? '',
      fileName: json['file_name'] ?? '',
      driveFileId: json['drive_file_id'] ?? '',
      sha256: json['sha256'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      uploadedAt: json['uploaded_at'] ?? '',
      version: json['version'] ?? 1,
      status: json['status'] ?? 'ACTIVE',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.95,
    );
  }
}

class RuleEvaluationModel {
  final String resultId;
  final String requirementId;
  final String status; // PASS, FAIL, REVIEW, PENDING
  final String ruleVersion;
  final String explanation;
  final String plainLanguageBidderMsg;
  final List<String> reasonCodes;
  final Map<String, dynamic> evaluatedValues;
  final String timestamp;
  final Map<String, dynamic>? officerOverride;

  RuleEvaluationModel({
    required this.resultId,
    required this.requirementId,
    required this.status,
    required this.ruleVersion,
    required this.explanation,
    required this.plainLanguageBidderMsg,
    required this.reasonCodes,
    required this.evaluatedValues,
    required this.timestamp,
    this.officerOverride,
  });

  factory RuleEvaluationModel.fromJson(Map<String, dynamic> json) {
    return RuleEvaluationModel(
      resultId: json['result_id'] ?? '',
      requirementId: json['requirement_id'] ?? '',
      status: json['status'] ?? 'PENDING',
      ruleVersion: json['rule_version'] ?? '',
      explanation: json['explanation'] ?? '',
      plainLanguageBidderMsg: json['plain_language_bidder_msg'] ?? '',
      reasonCodes: List<String>.from(json['reason_codes'] ?? []),
      evaluatedValues: Map<String, dynamic>.from(json['evaluated_values'] ?? {}),
      timestamp: json['timestamp'] ?? '',
      officerOverride: json['officer_override'],
    );
  }
}

class BidderApplicationModel {
  final String applicationId;
  final String tenderId;
  final String bidderCompanyName;
  final String bidderCompanyId;
  final String bidderUid;
  final String submittedAt;
  final String overallStatus; // DRAFT, IN_PROGRESS, READY_FOR_REVIEW, SUBMITTED, DECIDED
  final int completionPercent;
  final String? finalDecision; // QUALIFIED, DISQUALIFIED
  final String? decisionComments;
  final List<RuleEvaluationModel> results;

  BidderApplicationModel({
    required this.applicationId,
    required this.tenderId,
    required this.bidderCompanyName,
    this.bidderCompanyId = 'COMP-001',
    required this.bidderUid,
    required this.submittedAt,
    required this.overallStatus,
    required this.completionPercent,
    this.finalDecision,
    this.decisionComments,
    required this.results,
  });

  factory BidderApplicationModel.fromJson(Map<String, dynamic> json) {
    var resList = (json['results'] as List? ?? [])
        .map((r) => RuleEvaluationModel.fromJson(r))
        .toList();

    return BidderApplicationModel(
      applicationId: json['application_id'] ?? '',
      tenderId: json['tender_id'] ?? '',
      bidderCompanyName: json['bidder_company_name'] ?? '',
      bidderCompanyId: json['bidder_company_id'] ?? 'COMP-001',
      bidderUid: json['bidder_uid'] ?? '',
      submittedAt: json['submitted_at'] ?? '',
      overallStatus: json['overall_status'] ?? 'IN_PROGRESS',
      completionPercent: json['completion_percent'] ?? 0,
      finalDecision: json['final_decision'],
      decisionComments: json['decision_comments'],
      results: resList,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  bool read;
  final String? applicationId;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.read,
    this.applicationId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      applicationId: json['application_id'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class UserProfileModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String companyName;
  final String companyId;
  final String gstin;
  final bool active;

  UserProfileModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.companyName,
    required this.companyId,
    required this.gstin,
    required this.active,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'BIDDER',
      companyName: json['company_name'] ?? '',
      companyId: json['company_id'] ?? '',
      gstin: json['gstin'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
