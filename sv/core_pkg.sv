package core_pkg;

typedef struct packed {
    logic        valid;
    logic [31:0] pc;
    logic [31:0] instr;
} if_id_t;

endpackage
