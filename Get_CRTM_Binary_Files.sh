# Only download the file - save the unpacking for the docker build
filename="fix_REL-2.4.0.tgz" #rel 2.4.0 files
if [ ! -f "$filename" ]; then
    echo "downloading $filename, please wait about 5 minutes (3.2 GB tar file)"
    wget -q ftp://ftp.ssec.wisc.edu/pub/s4/CRTM/$filename #jedi set of CRTM binary files
else
    echo "$filename already exists, skipping download."
fi