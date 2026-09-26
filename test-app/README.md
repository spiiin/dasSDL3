# SDL3 test

C++17, CMake 3.24+, Git и компилятор C++ (Visual Studio Desktop development with C++).
SDL 3.4.16 автоматически загружается из GitHub при настройке и линкуется статически.

Выполните из папки test-app:

```powershell
cmake -S . -B build
cmake --build build --config Release
.\build\Release\sdl3_test.exe
```

Для одноконфигурационного генератора: `build/sdl3_test.exe`.
Приложение рисует движущийся квадрат. Выход: Escape или закрытие окна.
