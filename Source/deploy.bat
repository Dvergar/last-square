REM CLIENT BUILD 

openfl build ..\LD23.xml html5 -Ddeploy
REM SERVER BUILD

haxe -main ServerHelpers -python serverhelpers.py
haxe -main Common -python common.py
REM PUSH GAME SERVER

xcopy /Y server.py \\192.168.1.42\PiShare\
xcopy /Y common.py \\192.168.1.42\PiShare\
xcopy /Y serverhelpers.py \\192.168.1.42\PiShare\

REM PUSH WEB FILES
xcopy /Y /E ..\Export\html5\bin \\192.168.1.42\PiShare\site
xcopy /Y /E web \\192.168.1.42\PiShare\site