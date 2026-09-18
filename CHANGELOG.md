# Changelog

All notable changes to the Evergreen application will be documented in this file.

## [2.1.0] - 2026-09-18
### Added
- **Organize Pages** tool: page thumbnails, drag to reorder, rotate or remove pages, save as a new PDF.
- **Unlock PDF** tool: remove password protection from a PDF you have the password for.
- **Search in PDF viewer**: find text inside a document with next/previous match navigation (replaces the old "use OCR" hint).
- **Print**: print any PDF from the viewer or from the My Files options sheet.
- **Rename** documents from My Files (the file on disk is renamed too, so shared copies carry the new name).
- Unit tests for page-range parsing and file-name sanitising.

### Changed
- Upgraded dependencies: pdf_manipulator 5.0 (new Rust engine), cunning_document_scanner 3.0, file_picker 11, google_mobile_ads 9.1, ML Kit text recognition 0.16, open_file 4, and minor bumps across the board.
- Compression now downsamples images to a target resolution per level (72/150/220 ppi) in addition to JPEG quality.
- Output files use readable names (e.g. `report_protected.pdf`, `report_organized.pdf`) and never overwrite an existing file.
- Removed 8 unused dependencies (camera, lottie, permission_handler, cached_network_image, flutter_svg, intl, riverpod_annotation, shared_preferences).
- Minimum Android version is now 7.0 (API 24), required by the document scanner.
- Migrated deprecated APIs (`withOpacity`, `Share.shareXFiles`); analyzer is clean.

### Fixed
- Deleting a document now also deletes its file, reclaiming storage (only files Evergreen created are ever deleted).
- Scanning twice with the same name no longer overwrites the earlier scan.
- Split PDF reports ranges beyond the document's page count instead of silently skipping them.
- Unreadable white-on-white text in light mode on the Split, Encrypt, Watermark and Compress screens.
- Gradle daemon out-of-memory crashes during builds (JVM heap lowered from 8 GB to 3 GB).

## [1.0.1] - 2026-04-21
### Changed
- Transitioned application to a fully free, ad-supported monetization model.
- Removed legacy premium restrictions bridging to an unrestricted experience.
- Optimized ad placements to include unobtrusive banner ads and integrated native ads.
- Enforced clean code practices by clearing out deprecated methods and unused variables (`Share.shareXFiles`, `withOpacity`).

### Added
- Comprehensive README overview reflecting current functionalities.
- Introduced proper Changelog for tracking application versions.

## [1.0.0] - 2026-04-16
### Added
- Initial release featuring the core toolset: PDF Scanner, Image to PDF, Merge/Compress tools, ID Photo, and OCR.
- Integrated Hive local storage for document preservation.
- Applied clean UI architecture with a focused green aesthetic app theme.
