# Property Rental Project: Cleaning and Synchronization Script

## Overview
During the development of a **JSF-based property rental project**, I encountered critical issues managing photo uploads. The system relied on a database and a directory for storing and displaying property images. Over time, inconsistencies emerged, such as:

- **Non-existent photo references in the database:** Files referenced in the database were missing from the directory.
- **Unused photos in the directory:** Files present in the directory but not referenced in the database.
- **Corrupted filenames:** Filenames with incorrect extensions or invalid formats.
- **Performance issues:** The `advertisementImages` folder became so large that the development environment (Eclipse) slowed down significantly.

To address these challenges, I created a **Bash script** to clean, synchronize, and manage the `advertisementImages` folder and its relationship with the database.

---

## Features
1. **Identify and Remove Unused Photos:**
   - Detects photos in the `advertisementImages` folder that are not referenced in the database.
   - Removes these "junk files" to save space and improve performance.

2. **Handle Missing Photos:**
   - Identifies photos referenced in the database but missing from the folder.
   - Prompts the user to upload the missing files.

3. **Rename Corrupted Photos:**
   - Detects files with invalid or missing extensions.
   - Renames them using a timestamp and their detected MIME type.

4. **Synchronize Database and Folder:**
   - Updates the database with new filenames when files are renamed.
   - Ensures the folder and database are in sync.

5. **Relocate Unused Files:**
   - Moves unused photos to a temporary directory for manual review.

---

## Prerequisites
- **Linux Environment**: The script uses Bash shell commands.
- **MySQL Database**: Ensure the database connection is configured in `~/.my.cnf` for authentication.
- **Required Tools**:
  - `file`: For detecting MIME types.
  - `sed`: For processing database query results.

---

## Usage
### Script Arguments
The script expects two arguments:
1. **`imagesFolder`**: Path to the main `advertisementImages` directory.
2. **`imagesFolderToAdd`**: Path to a folder containing additional photos to be checked and added.

### Running the Script
```bash
chmod +x test.sh
./test.sh /path/to/advertisementImages /path/to/imagesFolderToAdd
```

### Output
The script will:
- Print logs of detected issues.
- Display actions taken (e.g., renaming, moving files).
- Indicate when manual intervention is required.

---

## Script Workflow
1. **Initialization**:
   - Reads images from the folder and the database.
   - Initializes arrays to track files and issues.

2. **Corrupted Filenames**:
   - Identifies files with missing or invalid extensions.
   - Renames them with valid extensions based on their MIME type.

3. **Unused Files**:
   - Compares folder contents with database records.
   - Removes files not referenced in the database.

4. **Missing Files**:
   - Prompts the user to upload missing photos.
   - Updates the database once files are added.

5. **Final Synchronization**:
   - Ensures the folder and database are fully synchronized.

---

## Key Functions
- **`lsCorruptedNames`**: Detects files with invalid extensions.
- **`excludeJunkFiles`**: Identifies and removes unused photos.
- **`addMissingDbFiles`**: Tracks database references without corresponding files.
- **`renamCorruptedNames`**: Renames corrupted filenames in the folder and updates the database.
- **`moveExtraPhotoFolder`**: Moves unused photos to a temporary folder for review.

---

## Improvements and Lessons Learned
- **Automation**: The script automates tedious tasks, reducing manual effort and errors.
- **Error Handling**: Improved error detection (e.g., invalid SQL syntax, missing files).
- **Performance**: Cleaning the folder significantly reduced the load on the development environment.
- **Scalability**: Designed to handle large numbers of files efficiently.

---

## Future Enhancements
1. **Logging**: Add structured logs for better traceability.
2. **GUI Integration**: Create a web interface for non-technical users.
3. **Cross-Platform Support**: Adapt the script for Windows and macOS.

---

## Contribution
Feel free to contribute by reporting issues or submitting pull requests on [GitHub](#).

---

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.


