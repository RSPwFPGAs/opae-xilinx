
cd xsim
rm xsim* webtalk* -rf

fim_path=${1:-../../src/ipi/fim_debug.bd.tcl}
echo $fim_path
if   [ $fim_path == ../../src/ipi/fim_debug.bd.tcl ]; then
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=axi_pcie3_0.inst.pcie3_ip_i/g' board.sh
elif [ $fim_path == ../../src/ipi/fim_default.bd.tcl ]; then
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=pcie3_ultrascale_0/g' board.sh
elif [ $fim_path == ../../src/ipi/fim_debug_u50dd.bd.tcl ]; then
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=xdma_0 -d U50DD=1/g' board.sh
else
	sed -i 's/xvlog_opts="--relax/xvlog_opts="--relax -d PCIE_INST=axi_pcie3_0.inst.pcie3_ip_i/g' board.sh
fi
sed -i 's/xsim board/xsim -gui -view ..\/..\/..\/src\/sim\/board_behav.wcfg -onerror stop -onfinish stop board/g' board.sh

sed -i 's/quit/ /g' cmd.tcl

bash board.sh -noclean_files

cd ..

