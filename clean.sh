#!/bin/bash

	
	declare -a suffix; 
	declare -a suffixArrayImgFolder; 
	declare -a SAIF;
	declare -a junkFiles;
	declare -a filesToAddToFolder;
	declare -a sqlToArray;
	declare -a imgToArray;
	declare -a imgExistInFolderNotInSql;
	declare -a imgExistInSqlNotInFolder;
	declare -r imagesFolder=$1;
	declare -r imagesFolderToAdd=$2;
	shopt -s nocasematch  # Enable case-insensitive matching

	IFS=$'\n';
	advertisementImages="/home/y/advertisementImages";
	imgFolderNotInSqlDB="$HOME/imgFolderNotInSqlDB";
	img=`ls /home/y/advertisementImages`;
	sql=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e 'SELECT imagePath FROM Property' | sed -e '/^$/d' -e 's/[[:space:]]*$//');
	resultat="";
		
	function lsCorruptedNames() {
		shopt -u nocasematch ; # Disable case-insensitive matching after use
		local let j=0;
		local arrayName=$2 ;
		SAIF=();
		 
		for i in $1
		do 
			if [[ ! $i =~ \.(jpg|jpeg|png|JPG|JPEG|PNG)$ ]]
				then
					SAIF[$j]="$i"; # modified
			fi
			((j++));
		done
		
		eval "$arrayName=(\"\${SAIF[@]}\")" # we quote the expanded values of the SAIF array (in order to To handle filenames with special characters)
	}
	
	# Photos that exist in advertisementImages Folder but not in DB
	function excludeJunkFiles() {
		local -n tmpArrMysql=$1; # Photos in the DataBase which its names does not end with .(png,jpg,jpeg)
		local -n tmpArrImg=$2;   # Photos in the advertisementImages Folder  which its names does not end with .(png,jpg,jpeg)
		local let imgSize=${#tmpArrImg[@]};
		local let j=0;
		local let n=$((imgSize-1));
		
		# need to remove dead / unused files
		if (( imgSize > 0 ))
			then
				for i in $(seq 0 $n)
					do
							isExist "${tmpArrImg[$i]}" tmpArrMysql; # it checks if an image does not exist in DB
							
							if [[ -n $resultat ]]; then
								junkFiles[$j]=$resultat # Photos to be removed from Folder
								((j++))
							fi
							resultat=""  # Reset resultat
					done
		fi
		
	}
	
	
	# Check if an element belong to the array
	function isExist() {
		local imgElement=$1;
		local -n imgArray=$2;
		local found=0;
		local let count=0;
		resultat="";
		for i in "${imgArray[@]}" 
			do
				if [[ "$i" != "$imgElement" ]]; 
					then 
					((count++));
				fi
			done
		# If not found, set resultat
		if ((count == ${#imgArray[@]})); then
		    resultat=$imgElement
		else
		    resultat=""
		fi
	}
	
	# Search Photos that exist in the SQL DB but not exist in DB Folder, 
	# Then put them in filesToAddToFolder to move them later
	function addMissingDbFiles() {
		echo "##################################### Start of addMissingDbFiles ###########################################";
		local -n sqlArrayImg=$1;
		local -n folderArrayImg=$2;
		local let size=$((${#sqlArrayImg[@]}-1));
		echo -e "\nsqlArrayImg :\n ${sqlArrayImg[@]}";
		echo "Size of sqlArrayImg : $size)"
		if (( size > 0 ))
			then
			echo "========== Inside Loop... ============="
			for i in $(seq 0 $size)
			do
				echo "sqlArrayImg[$i] : ${sqlArrayImg[$i]}";
				isExist "${sqlArrayImg[$i]}" folderArrayImg;
				
				if [[ -n $resultat ]]; then
					filesToAddToFolder[$j]=$resultat # Photos to be removed from Folder
					((j++))
				fi
				resultat=""  # Reset resultat
			done
			echo "========== end of Loop ================"
		fi
		echo "+++++++++++++ filesToAddToFolder ++++++++++++++++++";
		echo "##################################### End of addMissingDbFiles ###########################################";
	}
	
	function remove() {
	
		local -n filesToRemove=$1;
		local tmp="";
		for i in "${filesToRemove[@]}"
		do
			tmp="$imagesFolder/$i";
			if [[ -n $tmp ]]; then
				echo "Photo to Be Removed :"
				echo $tmp;
				rm -fv "$tmp";	
			fi
		done
	}
	
	function moveFiles() {
		local -n mvFrom="$2";
		local -n mvTo="$3";
		local -n mvWhat=$1;
			
		if [[ ${#mvWhat[@]} > 0 ]]; then
			for i in "${mvWhat[@]}"
				do
					echo "Moving $i from $mvFrom to $mvTo";
					mv "$mvFrom/$i" "$mvTo/$i";
				done
		else
			echo "No Photo To Move !";
		fi
	}
	
	function addMissingFiles() {
		local let j=0;
		local folderToCheck=$1;
		local photos=$(ls "$folderToCheck");
		local photosToArray=();
		
		# Move the new files to the folder with new names
		for i in $photos
		do
			local extension=$(echo "$i" | cut -f 2 -d .);
			local tmp=`date +%s%N`.$extension;
			mv "$1/$i" "$imagesFolder/$tmp";
			
			photosToArray[$j]="$tmp";
			((j++));
		done
		if [[ ${#photosToArray[@]} == ${#filesToAddToFolder[@]} ]]; then
			# Replace DataBase photos with New photo's folder names
			j=0;
			for i in ${filesToAddToFolder[@]}
			do
				update="UPDATE Property SET imagePath='${photosToArray[$j]}' WHERE imagePath='${i//\'/\'\'}'"; 
				sqlRequest=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e $update | sed -e '/^$/d' -e 's/[[:space:]]*$//');
				((j++));
				echo "sqlRequest : $sqlRequest updated photos !";
			done
			return;
		else
			echo -e "\nThe Given Photo Folder Does Not Contain The Same Number Of the Missing Photos";
			echo -e "\nPlease Note that the Folder Must Contains Exactelly [ ${#filesToAddToFolder[@]} ] Photos";
			echo -e "Click Enter When You Add ${#filesToAddToFolder[*]} Photos in the missing folder..."; 
			read response;
			
			addMissingFiles "$folderToCheck";
			echo "end of addMissingFiles"
			return;
		fi
		echo "Resp : $response";
		return;
	}
	
	function searchFolderPhotosNotInDB() {
		
		let j=0;
		
		for i in $sql
		do
			sqlToArray[$j]="$i";
			((j++));
		done
		
		j=0;
		
		for i in $img
		do
			imgToArray[$j]="$i";
			((j++));
		done
		
		j=0;
		# Photos which exist in sql but not in imgfolder
		for i in ${sqlToArray[@]}
		do
			isExist "$i" imgToArray;
			if [[ -n "$resultat" ]]; then
				imgExistInSqlNotInFolder[$j]="$resultat";
				((j++));
			fi
			resultat="";
		done
		
		resultat="";
		j=0;
		
		# Photos which exist in imgfolder but not in sql
		for i in ${imgToArray[@]}
		do
			isExist "$i" sqlToArray;
			if [[ -n "$resultat" ]]; then
				imgExistInFolderNotInSql[$j]="$resultat";
				((j++));
			fi
			resultat="";
		done
		
	}
	
	function moveExtraPhotoFolder() {
		echo -e "Start of moveExtraPhotoFolder...\n";
		# Call this function with : moveExtraPhotoFolder imgExistInSqlNotInFolder imgExistInFolderNotInSql
		local -n imgSqlNotInFolder=$1;
		local -n imgFolderNotInSql=$2;
		local -a imgSqlToFolder;
		#local let size=$((${#sqlArrayImg[@]}-1));
		TMPDIR="$HOME/imgFolderNotInSqlDB";
		
		# Copying imgFolderNotInSql Photos to /home/y/imgFolderNotInSqlDB
		if [[ ! -d $TMPDIR ]]; then
			mkdir $TMPDIR;
		else
		if [[ ${#imgFolderNotInSql[@]} > 0 ]]; then
			
			for i in ${imgFolderNotInSql[@]}
			do
				mv "$advertisementImages/$i" "$TMPDIR/$i";
			done
		fi
		fi
		
		# Move imgSqlNotInFolder
		# We expect (in my case) that imgFolderNotInSql was populated with extra unused photos, i will re-use them to solve the issue of existing 
		# photos in DB but they havn\'t its replacement in the advertisementImages folder 
		if [[ ${#imgSqlNotInFolder[@]} > 0 && ${#imgFolderNotInSql[@]} > ${#imgSqlNotInFolder[@]} ]]; then
			for i in $(seq 0 ${#imgSqlNotInFolder[@]})
				do
					if [[ -f "$TMPDIR/${imgFolderNotInSql[$i]}" ]]; then
						mv "$TMPDIR/${imgFolderNotInSql[$i]}" "$advertisementImages/${imgSqlNotInFolder[$i]}";
					else
						echo "The photo $TMPDIR/${imgFolderNotInSql[$i]} does Not Exist";
					fi
				done
		else
			echo "$TMPDIR is Empty !";
		fi
	}
	
	function renamCorruptedNames() {
		local -A sqlCorruptedPhotosArray; 
		local -A folderCorruptedPhotosArray;
		local -i j=0;
		local extension;
		local tmp;
		
		
		# Rename Corrupted Photos in DB :
		for i in "${suffix[@]}"
			do
				if [[ -f "$advertisementImages/$i" ]]; then
					extension=$(file --mime-type -b "$advertisementImages/$i" | cut -f 2 -d /);
					if [[ -n "$extension" ]]; then
						tmp=$(date +%s%N).$extension;
					else
						echo "Error: Unable to determine the file extension for $i"
						continue
					fi
					sqlCorruptedPhotosArray[$i]="$tmp";
				else
		        	echo "Error: Unable to determine file type for $i. Skipping."
		            continue
				fi
			done
		
		for key in "${!sqlCorruptedPhotosArray[@]}"
			do
				if [[ -f "$advertisementImages/$key" ]]; then
					mv "$advertisementImages/$key" "$advertisementImages/${sqlCorruptedPhotosArray[$key]}";
					update="UPDATE Property SET imagePath='${sqlCorruptedPhotosArray[$key]}' WHERE imagePath='${key//\'/\'\'}'";
					sqlRequest=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e $update | sed -e '/^$/d' -e 's/[[:space:]]*$//');
					if [[ $? -ne 0 ]]; then
		            	echo "Error executing SQL: $sqlRequest"
		        	fi
		        else
		       		echo "Error: File $advertisementImages/$key does not exist. Skipping."
           		fi
			done
		
		
		# Rename Corrupted Photos in Folder :
		for i in "${suffixArrayImgFolder[@]}"
			do
				if [[ -f "$advertisementImages/$i" ]]; then
					extension=$(file --mime-type -b "$advertisementImages/$i" | cut -f 2 -d /);
					if [[ -n "$extension" ]]; then
						tmp=$(date +%s%N).$extension;
					else
						echo "Error: Unable to determine the file extension for $i"
						continue
					fi
					folderCorruptedPhotosArray[$i]="$tmp";
				fi
			done
			
		for key in "${!folderCorruptedPhotosArray[@]}"
			do
				if [[ -f "$advertisementImages/$key" ]]; then
					mv "$advertisementImages/$key" "$advertisementImages/${folderCorruptedPhotosArray[$key]}";
					update="UPDATE Property SET imagePath='${folderCorruptedPhotosArray[$key]}' WHERE imagePath='${key//\'/\'\'}'";
					sqlRequest=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e $update | sed -e '/^$/d' -e 's/[[:space:]]*$//');
					if [[ $? -ne 0 ]]; then
				        echo "Error executing SQL: $sqlRequest"
				    fi
        		else
            		echo "Error: File $advertisementImages/$key does not exist. Skipping."
            	fi
			done
	}
	
	# Fill the suffix Array with corrupted Sql files names
	lsCorruptedNames "$sql" suffix;
	
	# Fill the suffixArrayImgFolder Array with corrupted Folder files names
	lsCorruptedNames "$img" suffixArrayImgFolder;
	
	# Photos that exist in Folder but not in DB, put them in junkFiles Array and remove them later
	excludeJunkFiles suffix suffixArrayImgFolder;
	
	echo -e "\n**********************************************************\n";
	echo -e "DB Images names to be modified (suffix) :\n${suffix[*]}\n"
	echo -e "**********************************************************\n";
	echo -e "Folder Images names to be modified (suffixArrayImgFolder) :\n${suffixArrayImgFolder[*]}\n"
	echo -e "**********************************************************\n";
	echo -e "Extra unwanted Folder Photos, To be removed (JunkFiles) :\n${junkFiles[*]}\n"
	
	# Search Photos that exist in the SQL DB but not exist in DB Folder, 
	# Then put them in filesToAddToFolder to move them later to the advertisementImages folder
	echo "addMissingDbFiles : Search Photos that exist in the SQL DB but not exist in DB Folder";
	addMissingDbFiles suffix suffixArrayImgFolder;
	echo "End of addMissingDbFiles Function..."
	echo -e "\n\nSQL images Must be Added to Folder (filesToAddToFolder) :\n\n${filesToAddToFolder[*]}";
	
	if [[ ${#filesToAddToFolder[@]} > 0 ]]; then
		echo;
		echo -e "addMissingFiles :\n"
		echo -e "Move the new files to the folder with new names, then Replace DataBase photos with New photo folder names\n"
		
		#Move the new files to the folder with new names, then Replace DataBase photos with New photo's folder names
		addMissingFiles $2;
	fi
	
	#remove junkFiles;
	echo -e "\nRemoving junkFiles...! : \n";
	if [[ ${#junkFiles[@]} != 0 ]]; then
		remove junkFiles;
		junkFiles=();
		
	fi
	echo -e "\njunkFiles Removed...! : \n";
	
	# Checking The DB and the advertisementImages Folder, then Correcting the photos names :
	
	suffix=();
	suffixArrayImgFolder=();
	img=`ls /home/y/advertisementImages`;
	sql=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e 'SELECT imagePath FROM Property' | sed -e '/^$/d' -e 's/[[:space:]]*$//');

	# Fill the suffix Array with corrupted Sql files names
	lsCorruptedNames "$sql" suffix;
	
	# Fill the suffixArrayImgFolder Array with corrupted Folder files names
	lsCorruptedNames "$img" suffixArrayImgFolder;
	
	echo -e "\n____________________________________________________________\n";
	echo -e "New suffix :\n${suffix[@]}"
	echo -e "\n____________________________________________________________\n";
	echo -e "New suffixArrayImgFolder :\n${suffixArrayImgFolder[@]}"
	
	echo -e "\nRenaming Corrupted Photos... \n";
	renamCorruptedNames;
	echo -e "\nRenaming Corrupted Photos Done \!\n"
	
	# Fill the suffix Array with corrupted Sql files names
	lsCorruptedNames "$sql" suffix;
	
	# Fill the suffixArrayImgFolder Array with corrupted Folder files names
	lsCorruptedNames "$img" suffixArrayImgFolder;
	
	echo -e "\n____________________________________________________________\n";
	echo -e "New(2) suffix :\n${suffix[@]}"
	echo -e "\n____________________________________________________________\n";
	echo -e "New(3) suffixArrayImgFolder :\n${suffixArrayImgFolder[@]}"
	
	# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
	
	echo '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\';
	echo -e "\nSearching Photos which exist in sql but not in folder...";
	echo -e "&";
	echo -e "Searching Photos which exist in imgfolder but not in sql\n";
	searchFolderPhotosNotInDB;
	echo -e "\nSearching Photos Done \!\n"
	echo '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\';
	
	echo -e "\n///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////";
	IFS=$'\n';
	echo -e "\nPhotos which exist in sql but not in imgfolder\n\n";
	# Photos which exist in sql but not in imgfolder
		for ((i=0; i<${#imgExistInSqlNotInFolder[@]}; i++))
		do
			echo "${imgExistInSqlNotInFolder[$i]}";
		done
		echo "sql : ${#imgExistInSqlNotInFolder[@]}";
		
		echo -e "\n\nPhotos which exist in imgfolder but not in sql\n\n";
		# Photos which exist in imgfolder but not in sql
		for ((i=0; i<${#imgExistInFolderNotInSql[@]}; i++))
		do
			echo "${imgExistInFolderNotInSql[$i]}";
			#((j++));
		done
		echo "imgfolder : ${#imgExistInFolderNotInSql[@]}";
	
	
	img=`ls /home/y/advertisementImages`;
	sql=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e 'SELECT imagePath FROM Property' | sed -e '/^$/d' -e 's/[[:space:]]*$//');
	imgExistInSqlNotInFolder=();
	imgExistInFolderNotInSql=();
	sqlToArray=();
	imgToArray=();
	searchFolderPhotosNotInDB;
	moveExtraPhotoFolder imgExistInSqlNotInFolder imgExistInFolderNotInSql;
	
	echo "End of cleaning DataBase & advertisementImages Folder... By !";
	echo -e "\n///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////";
	# clear; ./test.sh "/home/y/Desktop/advertisementImages" "/home/y/Desktop/missing" 
	
