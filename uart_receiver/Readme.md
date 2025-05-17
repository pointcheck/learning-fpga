sudo screen /dev/ttyUSB1 115200,cs8,even,ixoff,-istrip
# Для screen (параметры: скорость, четность, стоп-биты)
    /dev/ttyUSB0 - UART-устройство

    115200 - скорость передачи (baud rate)

    cs8 - 8 бит данных

    even - чётная четность (even parity)

    ixoff - отключение управления потоком

    -istrip - не обрезать 8-й бит

screen /dev/ttyUSB1 115200,cs8,even,ixoff,-istrip,-cstopb

    -cstopb = 1 стоп-бит (по умолчанию)

    cstopb = 2 стоп-бита

Настройки четности:
even Чётная
odd	Нечётная
-parity	Без проверки чётности

minicom (лучше для сложных настроек):

minicom -D /dev/ttyUSB0 -b 115200 --8bit --parity=odd --stop=2
