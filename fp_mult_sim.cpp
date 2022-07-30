// Run with verilator --top FP_Adder --cc --exe --build fp_mult*

#include "obj_dir/VFP_Multiplicator.h"
#include "verilated.h"
#include <iostream>
#include <random>
#include <limits>

#define FUZZ_TESTS 10000

constexpr uint32_t extract_float_bits(float a) {
    return *(uint32_t*) (&a);
}

constexpr float float_from_bits(uint32_t a) {
    return *(float*) (&a);
}

float random_float() {
    static std::random_device rd;
    static std::mt19937 e2(rd());
    static std::uniform_real_distribution<> dist(-1000, 1000);
    return dist(e2);
}

void test_number(VFP_Multiplicator& module, float a, float b) {
    constexpr float epsilon = 1e-4;
    module.a = extract_float_bits(a);
    module.b = extract_float_bits(b);
    module.eval();
    float expected = a * b;
    float got = float_from_bits(module.result);
    if (std::abs(expected - got) > epsilon && !(std::isnan(got) && std::isnan(expected)) && std::abs((int32_t)module.result - (int32_t)extract_float_bits(expected)) > 1)
        std::cout << "Invalid result on " << a << " * " << b <<
        ": Expected " << expected << " but got " << got <<
        "; difference of these numbers are: " << std::abs(expected - got) << std::endl;
}

int main(int argc, char** argv, char** env) {
    std::cout << "TEST STARTED" << std::endl;
    VerilatedContext context;
    context.commandArgs(argc, argv);
    VFP_Multiplicator top(&context);
    // Hardcoded tests
    test_number(top, -342.175, -855.408);
    test_number(top, 0.15625, 0.15625);
    test_number(top, 0.3125, 0.15625);
    // Zero tests
    test_number(top, 0, 0);
    test_number(top, 1, 0);
    test_number(top, 0.5, 0);
    test_number(top, -0.5, 0);
    test_number(top, -1, 0);
    test_number(top, 0, 1);
    test_number(top, 0, 0.5);
    test_number(top, 0, -0.5);
    test_number(top, 0, -1);
    // Infinity tests
    test_number(top, std::numeric_limits<float>::infinity(), 1);
    test_number(top, std::numeric_limits<float>::infinity(), 0);
    test_number(top, std::numeric_limits<float>::infinity(), -1);
    test_number(top, std::numeric_limits<float>::infinity(), std::numeric_limits<float>::infinity());
    test_number(top, std::numeric_limits<float>::infinity(), -std::numeric_limits<float>::infinity());
    test_number(top, 1, std::numeric_limits<float>::infinity());
    test_number(top, 0, std::numeric_limits<float>::infinity());
    test_number(top, -1, std::numeric_limits<float>::infinity());
    test_number(top, -std::numeric_limits<float>::infinity(), std::numeric_limits<float>::infinity());
    // NaN tests
    test_number(top, std::numeric_limits<float>::quiet_NaN(), 1);
    test_number(top, std::numeric_limits<float>::quiet_NaN(), 0);
    test_number(top, std::numeric_limits<float>::quiet_NaN(), -1);
    test_number(top, std::numeric_limits<float>::quiet_NaN(), std::numeric_limits<float>::quiet_NaN());
    test_number(top, std::numeric_limits<float>::quiet_NaN(), -std::numeric_limits<float>::quiet_NaN());
    test_number(top, 1, std::numeric_limits<float>::quiet_NaN());
    test_number(top, 0, std::numeric_limits<float>::quiet_NaN());
    test_number(top, -1, std::numeric_limits<float>::quiet_NaN());
    test_number(top, -std::numeric_limits<float>::quiet_NaN(), std::numeric_limits<float>::quiet_NaN());
    test_number(top, std::numeric_limits<float>::signaling_NaN(), 1);
    test_number(top, std::numeric_limits<float>::signaling_NaN(), 0);
    test_number(top, std::numeric_limits<float>::signaling_NaN(), -1);
    test_number(top, std::numeric_limits<float>::signaling_NaN(), std::numeric_limits<float>::signaling_NaN());
    test_number(top, std::numeric_limits<float>::signaling_NaN(), -std::numeric_limits<float>::signaling_NaN());
    test_number(top, 1, std::numeric_limits<float>::signaling_NaN());
    test_number(top, 0, std::numeric_limits<float>::signaling_NaN());
    test_number(top, -1, std::numeric_limits<float>::signaling_NaN());
    test_number(top, -std::numeric_limits<float>::signaling_NaN(), std::numeric_limits<float>::signaling_NaN());
    // Fuzz with one zero
    for (int i = 0; i < FUZZ_TESTS; i++) {
        float other = random_float();
        test_number(top, 0, other);
        test_number(top, other, 0);
    }
    // Fuzz tests with two random numbers
    for (int i = 0; i < FUZZ_TESTS; i++) {
        float a = random_float(), b = random_float();
        test_number(top, a, b);
        test_number(top, b, a);
    }
    // Done
    std::cout << "TEST DONE" << std::endl;
    return 0;
}