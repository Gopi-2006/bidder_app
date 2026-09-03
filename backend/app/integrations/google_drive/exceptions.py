class DriveAPIException(Exception):
    """Base exception for Google Drive API operations."""
    pass


class FolderNotFoundException(DriveAPIException):
    """Raised when a specified folder cannot be found or accessed in Google Drive."""
    pass


class FileUploadException(DriveAPIException):
    """Raised when a file upload operation fails in Google Drive."""
    pass


class FileDownloadException(DriveAPIException):
    """Raised when a file download operation fails in Google Drive."""
    pass
