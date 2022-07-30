// Run with verilator -Wall -Wno-DECLFILENAME --top FP_Negator --cc --exe --build fp_negator_sim.cpp fp_negator.sv && obj_dir/VFP_Negator

#include "obj_dir/VFP_Negator.h"
#include "verilated.h"
#include <iostream>
#include <random>

#define FUZZ_TESTS 1000

constexpr uint32_t extract_float_bits(float a) {
    return *(uint32_t*) (&a);
}

constexpr float float_from_bits(uint32_t a) {
    return *(float*) (&a);
}

float random_float() {
    static std::random_device rd;
    static std::mt19937 e2(rd());
    static std::uniform_real_distribution<> dist(0, 1);
    return dist(e2);
}

void test_number(VFP_Negator& module, float test_case) {
    float expected = -test_case;
    module.a = extract_float_bits(test_case);
    module.eval();
    float result = float_from_bits(module.result);
    if (std::isnan(test_case) && std::isnan(result)) // if both are NaN we are good
        return;
    if (result != expected)
        std::cout << "INVALID OUTPUT FOR FUZZ TEST: input: " << test_case << " got " << result << std::endl;
}

int main(int argc, char** argv, char** env) {
    VerilatedContext context;
    context.commandArgs(argc, argv);
    VFP_Negator top(&context);
    // Especial tests:
    top.a = extract_float_bits(0);
    top.eval(); 
    if (top.result != 0)
        std::cout << "INVALID OUTPUT FOR ZERO TEST: " << float_from_bits(top.result) << std::endl;
    test_number(top, std::numeric_limits<float>::infinity());
    test_number(top, std::numeric_limits<float>::quiet_NaN());
    test_number(top, std::numeric_limits<float>::signaling_NaN());
    test_number(top, -std::numeric_limits<float>::infinity());
    test_number(top, -std::numeric_limits<float>::quiet_NaN());
    test_number(top, -std::numeric_limits<float>::signaling_NaN());
    // Fuzz
    for (int i = 0; i < FUZZ_TESTS; i++) {
        float test_case = random_float();
        test_number(top, test_case);
    }
    // Done
    std::cout << "TEST DONE" << std::endl;
    return 0;
}