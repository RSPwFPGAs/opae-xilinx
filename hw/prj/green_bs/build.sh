
rm ./dcp -rf
mkdir dcp
cp ../blue_bs/export/* ./dcp/.

rm ./output -rf
mkdir output

vivado -mode batch -source run_proj.tcl

