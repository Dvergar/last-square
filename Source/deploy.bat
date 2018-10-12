openfl build ..\LD23.xml html5 -Ddeploy
haxe -main ServerHelpers -python serverhelpers.py
haxe -main Common -python common.py
xcopy /Y server.py \\192.168.1.42\PiShare\
xcopy /Y common.py \\192.168.1.42\PiShare\
xcopy /Y serverhelpers.py \\192.168.1.42\PiShare\
xcopy /Y /E ..\Export\html5\bin \\192.168.1.42\PiShare\site