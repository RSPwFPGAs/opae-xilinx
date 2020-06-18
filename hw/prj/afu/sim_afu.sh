
cd xsim
rm xsim* webtalk* -rf

sed -i 's/xsim tb/xsim -gui -view ..\/..\/..\/src\/sim\/afu\/tb_behav.wcfg tb/g' tb.sh
sed -i 's/quit/#quit/g' cmd.tcl

bash tb.sh -noclean_files

cd ..

