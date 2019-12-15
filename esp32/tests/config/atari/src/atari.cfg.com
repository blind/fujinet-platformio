FEATURES {
    STARTADDRESS: default = $2000;
}
SYMBOLS {
    __EXEHDR__:          type = import;
    __AUTOSTART__:       type = import;  # force inclusion of autostart "trailer"
    __STACKSIZE__:       type = weak, value = $0800; # 2k stack
    __STARTADDRESS__:    type = export, value = %S;
    __RESERVED_MEMORY__: type = weak, value = $0000;
}
MEMORY {
    ZP:         file = "", define = yes, start = $0082, size = $007E;

# file header, just $FFFF
    HEADER:     file = %O,               start = $0000, size = $0002;

# "main program" load chunk
    MAINHDR:    file = %O,               start = $0000, size = $0004;
    MAIN:       file = %O, define = yes, start = %S,    size = $BC20 - __STACKSIZE__ - __RESERVED_MEMORY__ - %S;
    TRAILER:    file = %O,               start = $0000, size = $0006;
}
SEGMENTS {
    ZEROPAGE:  load = ZP,         type = zp;
    EXTZP:     load = ZP,         type = zp,                optional = yes;
    EXEHDR:    load = HEADER,     type = ro;
    MAINHDR:   load = MAINHDR,    type = ro;
    STARTUP:   load = MAIN,       type = ro,  define = yes;
    LOWBSS:    load = MAIN,       type = rw,                optional = yes;  # not zero initialized
    LOWCODE:   load = MAIN,       type = ro,  define = yes, optional = yes;
    ONCE:      load = MAIN,       type = ro,                optional = yes;
    CODE:      load = MAIN,       type = ro,  define = yes;
    RODATA:    load = MAIN,       type = ro;
    DATA:      load = MAIN,       type = rw;
    INIT:      load = MAIN,       type = rw,                optional = yes;
    BSS:       load = MAIN,       type = bss, define = yes;
    AUTOSTRT:  load = TRAILER,    type = ro;
}
FEATURES {
    CONDES: type    = constructor,
            label   = __CONSTRUCTOR_TABLE__,
            count   = __CONSTRUCTOR_COUNT__,
            segment = ONCE;
    CONDES: type    = destructor,
            label   = __DESTRUCTOR_TABLE__,
            count   = __DESTRUCTOR_COUNT__,
            segment = RODATA;
    CONDES: type    = interruptor,
            label   = __INTERRUPTOR_TABLE__,
            count   = __INTERRUPTOR_COUNT__,
            segment = RODATA,
            import  = __CALLIRQ__;
}
