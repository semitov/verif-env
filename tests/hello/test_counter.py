"""Hello-world test for the SemiTO-V verification image.

Passing it proves Verilator, cocotb, pyuvm and cocotb-coverage all work
together. Run it with `make` in this folder (`make WAVES=1` for a waveform).
"""

import cocotb
import pyuvm
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge
from cocotb_coverage.coverage import CoverPoint, coverage_db
from pyuvm import uvm_test

CYCLES = 300  # more than 256, so the 8-bit counter wraps around once
WIDTH = 8


# Functional coverage: did the counter reach its maximum value and wrap to 0?
@CoverPoint("hello.count", xf=lambda value: value, bins=[0, 2**WIDTH - 1], bins_labels=["zero", "max"])
def sample_count(value):
    pass


@pyuvm.test()
class HelloTest(uvm_test):
    """Count for CYCLES clock edges, then check the value and the coverage."""

    async def run_phase(self):
        self.raise_objection()
        dut = cocotb.top

        cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

        # Reset
        dut.en.value = 0
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 2)
        await FallingEdge(dut.clk)
        dut.rst_n.value = 1
        assert int(dut.count.value) == 0, "count is not 0 after reset"

        # Count, sampling coverage on every falling edge (values are stable there)
        dut.en.value = 1
        for _ in range(CYCLES):
            await FallingEdge(dut.clk)
            sample_count(int(dut.count.value))
        dut.en.value = 0
        await ClockCycles(dut.clk, 3)

        expected = CYCLES % 2**WIDTH
        got = int(dut.count.value)
        assert got == expected, f"count is {got}, expected {expected}"
        self.logger.info("Counter reached %d after %d enabled cycles", got, CYCLES)

        coverage_db.report_coverage(self.logger.info, bins=True)
        coverage_db.export_to_xml(filename="coverage.xml")
        assert coverage_db["hello.count"].cover_percentage == 100, "coverage holes left"

        self.drop_objection()
