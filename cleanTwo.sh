#!/bin/bash

	declare sqlSelect;
	declare lsFolder;
	declare lsImgNotInSqlVar
	declare -a sqlSelectArray;
	declare -a lsFolderArray;
	declare -a lsImgFolderNotInSqlArray;
	declare -a imgExistInSqlNotInFolder;
	declare -a imgExistInFolderNotInSql;
	declare advertisementImages="$HOME/advertisementImages";
	declare imgFolderNotInSqlDB="$HOME/imgFolderNotInSqlDB";
	declare resultat="";
	declare -a validImgArray;
	declare -a equalImgsArray;
	declare tmpCopiedPhotosDir;
	let sqlNumLignes;
	let folderNumLignes;
	let imgNotInSqlNumLignes;
	let j=0;
	let lenghtOfStr=0;
	IFS=$'\n';
	
	# Request imgPath column in DB
	function sqlSelectImgPath() {
		IFS=$'\n';
		sqlSelect=$(mysql --defaults-file=~/.my.cnf -D propertyRentals -N -e 'SELECT imagePath FROM Property' | sed -e '/^$/d' -e 's/[[:space:]]*$//');
		sqlNumLignes=$(wc -l <<< "$sqlSelect");
	}
	
	# Assign the result of ls advertisementImages
	function lsFolderPhotos() {
		IFS=$'\n';
		lsFolder=$(ls "$advertisementImages");
		folderNumLignes=$(wc -l <<< "$lsFolder");
	}
	
	function lsImgFolderNotInSqlDB() {
		IFS=$'\n';
		lsImgNotInSqlVar=$(ls "$imgFolderNotInSqlDB");
		imgNotInSqlNumLignes=$(wc -l <<< "$lsImgNotInSqlVar");
	}
	
	# Transform sqlSelect Request to array
	
	function sqlSelectToArray() {
		if [[ -n $sqlSelect ]]; then
			for i in $sqlSelect
				do
					sqlSelectArray[$j]="$i";
					((j++));
				done
		fi
	}
	
	let k=0;
	# Transform lsFolder cmd conent to array
	function lsFolderToArray() {
	
		if [[ -n $lsFolder ]]; then
			for i in $lsFolder
				do
					lsFolderArray[$k]="$i";
					((k++));
				done
		fi
		unset k;
	}
	
	let l=0;
	# Transform lsImgNotInSqlVar cmd conent to array
	function lsImgFolderNotInSqlToArray() {
	
		if [[ -n $lsImgNotInSqlVar ]]; then
			for i in $lsImgNotInSqlVar
				do
					lsImgFolderNotInSqlArray[$l]="$i";
					((l++));
				done
		fi
		unset l;
	}
	
	function maxLenght() {
		local -n arrayParam=$1;
		local let maxTmp=${#arrayParam[0]};
		for (( i=0; i < ${#arrayParam[@]} ; i++ ))
			do
				if (( maxTmp < ${#arrayParam[$i]} )); then
					maxTmp=${#arrayParam[$i]};
				fi
			done
		lenghtOfStr=$maxTmp;
	}
		
	function printHyphen() {
		local let numOfHyph=$1;
		for (( i=0; i < numOfHyph ; i++ ))
			do
				printf "-";
			done
		printf "\n";
	}
	
	function printArray() {
		local -n myArray=$1;
		maxLenght myArray;
		
		let m=$((lenghtOfStr+4));
		if [[ ${myArray[@]} > 0 ]]; then
			printHyphen $m;
		fi
		for i in "${myArray[@]}"
			do
				let space=$((lenghtOfStr-${#i}));
				printf "| %s%*s |\n" "$i" "$space" ;
				printHyphen $m;
			done
	}
	
	# ============================================
	
	# Check if an element belong to the array
	function isExist() {
		local imgElement=$1;
		local -n imgArray=$2;
		local let count=0;
		resultat="";
		for i in "${imgArray[@]}" 
			do
				if [[ "$i" != "$imgElement" ]]; then 
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
	
	function searchFolderPhotosNotInDB() {
		sqlSelectImgPath;
		lsFolderPhotos;
		
		sqlSelectToArray;
		lsFolderToArray;
		
		let j=0;
		resultat="";
		# Photos which exist in sql but not in imgfolder
		for i in ${sqlSelectArray[@]}
			do
				isExist "$i" lsFolderArray;
				if [[ -n "$resultat" ]]; then
					imgExistInSqlNotInFolder[$j]="$resultat";
					((j++));
				fi
				resultat="";
			done
		
		resultat="";
		let j=0;
		
		# Photos which exist in imgfolder but not in sql
		for i in ${lsFolderArray[@]}
			do
				isExist "$i" sqlSelectArray;
				if [[ -n "$resultat" ]]; then
					imgExistInFolderNotInSql[$j]="$resultat";
					((j++));
				fi
				resultat="";
			done
		
	}
	
	function checkFileExist() {
		local imgElement=$1;
		local -n imgArray=$2;
		local let count=0;
		resultat="";
		
		for i in "${imgArray[@]}" 
			do
				if [[ "$i" == "$imgElement" ]]; then 
					result="$imgElement";
					break;
				else
					resultat="";
				fi
			done
	}
	
	function makeDir() {
		if [[ ! -d $1 ]]; then
			mkdir $1;
		fi
	}
	
	function fixMissingPhotos() {
		let numImgSqlNotFolder=${#imgExistInSqlNotInFolder[@]};
		let b=0;
		# imgExistInSqlNotInFolder size Must Be > lsImgFolderNotInSqlArray size
		echo ${#lsImgFolderNotInSqlArray[@]};
		echo ${#imgExistInSqlNotInFolder[@]};
		
		if [[ ${#lsImgFolderNotInSqlArray[@]} -gt ${#imgExistInSqlNotInFolder[@]} ]]; then
			
			 #=============
			 for i in "${imgExistInSqlNotInFolder[@]}"
				do
					checkFileExist "$i" lsImgFolderNotInSqlArray;
					if [[ -n "$result" ]]; then
						equalImgsArray[$b]="$result";
						((b++));
					fi
				done
			 #=============
			
			b=0;
			tmpCopiedPhotosDir="/home/y/tmpCopiedPhotosDir";
			makeDir $tmpCopiedPhotosDir;
			
			for i in "${imgExistInSqlNotInFolder[@]}"
				do
					if [[ -f "$imgFolderNotInSqlDB/${lsImgFolderNotInSqlArray[$b]}" ]]; then
						cp "$imgFolderNotInSqlDB/${lsImgFolderNotInSqlArray[$b]}" $tmpCopiedPhotosDir/$i;
					else
						echo "$imgFolderNotInSqlDB/${lsImgFolderNotInSqlArray[$b]} : Does Not Exist !";
					fi
						((b++));
				done
		fi
		echo ${#lsImgFolderNotInSqlArray[@]};
		let copied=$(ls $tmpCopiedPhotosDir | wc -l);
		echo $copied;
		
	}
	# ====================================================
	
	sqlSelectImgPath;
	lsFolderPhotos;
	lsImgFolderNotInSqlDB;
	
	sqlSelectToArray;
	lsFolderToArray;
	lsImgFolderNotInSqlToArray
	
	searchFolderPhotosNotInDB;
	
	printf "\n%s\n" "Photos that Exist in SQL But Not In Folder :";
	printArray imgExistInSqlNotInFolder;
	printf "\n%s%d\n" "All img Number in SQL : " $sqlNumLignes;
	printf "\n%s%d\n" "Number of imgs in SQL But Not In Folder : " ${#imgExistInSqlNotInFolder[@]};
	
	echo -e "\n\n===================================================\n\n";
	
	printf "\n%s\n" "Photos that Exist in Folder But Not In SQL :";
	printArray imgExistInFolderNotInSql;
	printf "\n%s%d\n" "All img Number in AdvertismentImages : " $folderNumLignes;
	printf "\n%s%d\n" "Number of imgs in Folder But Not In SQL : " ${#imgExistInFolderNotInSql[@]};
	
	printf "\n%s\n" "Photos that Exist in imgFolderNotInSqlDB :";
	printArray lsImgFolderNotInSqlArray;
	printf "\n%s%d\n" "img Number : " $imgNotInSqlNumLignes;
	
	# -----------------------------------------------------
	
	fixMissingPhotos;
	
	echo -e "\n\n===================================================\n\n";
	
	printf "\n%s\n" "equalImgsArray Photos :";
	printArray equalImgsArray;
	printf "\n%s%d\n" "Number Of equal Images : " ${equalImgsArray[@]};
	
	#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	
	
