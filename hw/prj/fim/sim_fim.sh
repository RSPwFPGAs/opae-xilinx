
cd xsim
rm xsim* webtalk* -rf

echo $1
if   [ $1 == ../../src/ipi/fim_debug.bd.tcl ]; then
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=axi_pcie3_0.inst.pcie3_ip_i/g' board.sh
elif [ $1 == ../../src/ipi/fim_default.bd.tcl ]; then
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=pcie3_ultrascale_0/g' board.sh
fi
sed -i 's/xsim board/xsim -gui -view ..\/..\/..\/src\/sim\/board_behav.wcfg board/g' board.sh
bash board.sh -noclean_files

cd ..

