#!/bin/bash



	declare lsFolder="/home/y/Desktop/BashScript/advertisementImages";



	# Compress with 50% of size and 80% of quality
	function compress() {
		mogrify -debug All -resize 70% -quality 60% "$1";
		#convert "$img" -resize 50% -quality 80% "/home/user/compressed_photos/$(basename "$img")"

	}
	
	function doCompressAll() {
		for i in $lsFolder/*
			do
				compress "$i";
			done
	}
	
	# Print folder size before compression
	echo "Folder size before compression:"
	du -h -d 0 $lsFolder;
	
	doCompressAll;
	
	# Print folder size before compression
	echo "Folder size before compression:"
	du -h -d 0 $lsFolder;
