::-------------生成rootfs.iso
call fsbuild.bat

::-------------生成rootfs.az
..\..\..\..\eStudio\Softwares\az\az e rootfs.iso setup\rootfs.az -fastmode
del rootfs.iso

::-------------生成zdisk.img
pushd .
cd setup
call makezdisk.bat
popd

::-------------计算zdisk.img的校验值
..\..\..\..\eStudio\Softwares\eDragonEx200\FileAddSum.exe  setup\zdisk.img  ..\eFex\verify.fex

::-------------生成ePDKv100.img
del ePDKv100.img
..\..\..\..\eStudio\Softwares\eDragonEx200\dragon image.cfg  > image.txt
del image.bin

pushd .
cd setup
del zdisk.img
del rootfs.az
popd

pushd .
cd ..\efex
del verify.fex
popd

pause
