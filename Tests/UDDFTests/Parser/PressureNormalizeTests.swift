import Foundation
import Testing
@testable import UDDF

/// Unit tests for PressureNormalize.po2 — the value-range heuristic that
/// rescues non-compliant PPO₂ values (bar written where Pa is required by
/// UDDF v3.2.1). See `Documentation/uddf-v3.2.1/calculatedpo2.html`.
struct PressureNormalizeTests {

    // MARK: - Pure helper

    @Test func po2_paValuePassesThrough() {
        let result = PressureNormalize.po2(127_000)
        #expect(result.value == 127_000)
        #expect(result.wasNormalized == false)
    }

    @Test func po2_typicalShearwaterBarValueNormalized() {
        // Real sample from a Shearwater Cloud Desktop export: 0.72 bar
        let result = PressureNormalize.po2(0.72)
        #expect(abs(result.value - 72_000) < 0.01)
        #expect(result.wasNormalized == true)
    }

    @Test func po2_highOxBarValueNormalized() {
        // 1.4 bar setpoint, common CCR diluent ceiling
        let result = PressureNormalize.po2(1.4)
        #expect(abs(result.value - 140_000) < 0.01)
        #expect(result.wasNormalized == true)
    }

    @Test func po2_zeroPassesThrough() {
        // Value of 0 means "no reading" — don't normalize, just pass through.
        let result = PressureNormalize.po2(0)
        #expect(result.value == 0)
        #expect(result.wasNormalized == false)
    }

    @Test func po2_negativePassesThrough() {
        // Nonsense value; pass through so the caller can decide.
        let result = PressureNormalize.po2(-1)
        #expect(result.value == -1)
        #expect(result.wasNormalized == false)
    }

    @Test func po2_boundaryAt100PaStaysAsPa() {
        // 100 is the cutoff — anything at or above is already Pa.
        // Below 100 Pa is a physical vacuum and can only be bar.
        let result = PressureNormalize.po2(100)
        #expect(result.value == 100)
        #expect(result.wasNormalized == false)
    }

    @Test func po2_justBelowBoundaryNormalized() {
        let result = PressureNormalize.po2(99.9)
        #expect(abs(result.value - 9_990_000) < 0.01)
        #expect(result.wasNormalized == true)
    }

    // MARK: - With-diagnostics wrapper

    @Test func normalizedPO2_emitsDiagnosticOnNormalize() {
        var diags: [ParseDiagnostic] = []
        let result = PressureNormalize.normalizedPO2(
            0.72, element: "calculatedpo2",
            context: "dive/samples/waypoint[170s]",
            diagnostics: &diags
        )
        #expect(abs((result ?? 0) - 72_000) < 0.01)
        #expect(diags.count == 1)
        #expect(diags[0].level == .warning)
        #expect(diags[0].message.contains("calculatedpo2"))
        #expect(diags[0].message.contains("0.72"))
        #expect(diags[0].context == "dive/samples/waypoint[170s]")
    }

    @Test func normalizedPO2_quietOnCompliantValue() {
        var diags: [ParseDiagnostic] = []
        let result = PressureNormalize.normalizedPO2(
            127_000, element: "calculatedpo2",
            context: "wp",
            diagnostics: &diags
        )
        #expect(result == 127_000)
        #expect(diags.isEmpty)
    }

    @Test func normalizedPO2_nilRawReturnsNil() {
        var diags: [ParseDiagnostic] = []
        let result = PressureNormalize.normalizedPO2(
            nil, element: "setpo2",
            context: "wp",
            diagnostics: &diags
        )
        #expect(result == nil)
        #expect(diags.isEmpty)
    }

    @Test func normalizedPO2Readings_normalizesEach() {
        var diags: [ParseDiagnostic] = []
        let input = [
            UDDFSensorReading(ref: "s1", value: 0.72),
            UDDFSensorReading(ref: "s2", value: 125_000),     // already Pa
            UDDFSensorReading(ref: "s3", value: 0.68),
        ]
        let result = PressureNormalize.normalizedPO2Readings(
            input, element: "measuredpo2",
            context: "wp",
            diagnostics: &diags
        )
        #expect(result.count == 3)
        #expect(abs(result[0].value - 72_000) < 0.01)
        #expect(result[0].ref == "s1")
        #expect(result[1].value == 125_000)
        #expect(result[1].ref == "s2")
        #expect(abs(result[2].value - 68_000) < 0.01)
        #expect(diags.count == 2)           // s1 and s3 triggered, s2 quiet
    }

    // MARK: - Interpreter integration

    /// Synthetic fixture with bar-valued <calculatedpo2> — verify the
    /// StandardUDDFInterpreter normalizes it through to Pa and emits a
    /// diagnostic.
    @Test func standardInterpreter_normalizesBarPO2() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <uddf xmlns="http://www.streit.cc/uddf/3.2/" version="3.2.0">
          <generator><name>SyntheticTest</name><version>1.0</version></generator>
          <gasdefinitions>
            <mix id="air"><name>Air</name><o2>0.21</o2><he>0.0</he></mix>
          </gasdefinitions>
          <profiledata>
            <repetitiongroup>
              <dive>
                <informationbeforedive><datetime>2026-04-15T10:00:00</datetime></informationbeforedive>
                <samples>
                  <waypoint>
                    <divetime>0</divetime><depth>0</depth>
                    <switchmix ref="air"/>
                    <divemode type="opencircuit"/>
                  </waypoint>
                  <waypoint>
                    <divetime>170</divetime><depth>11.19</depth>
                    <calculatedpo2>0.72</calculatedpo2>
                  </waypoint>
                </samples>
              </dive>
            </repetitiongroup>
          </profiledata>
        </uddf>
        """
        let data = Data(xml.utf8)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)

        // Find the waypoint with the normalized ppo2
        let wp = result.document.dives.first?.waypoints.first { $0.calculatedPO2 != nil }
        #expect(wp != nil)
        if let po2 = wp?.calculatedPO2 {
            #expect(abs(po2 - 72_000) < 0.01,
                    "expected 72000 Pa, got \(po2)")
        }

        // Diagnostic emitted
        let ppo2Diags = result.diagnostics.filter {
            $0.level == .warning && $0.message.contains("calculatedpo2")
        }
        #expect(ppo2Diags.count == 1)
    }

    /// Shearwater path — same fixture but with Shearwater in the
    /// generator name so InterpreterFactory picks ShearwaterInterpreter.
    /// Verifies the normalization is wired into that path, not only
    /// StandardUDDFInterpreter.
    @Test func shearwaterInterpreter_normalizesBarPO2() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <uddf xmlns="http://www.streit.cc/uddf/3.2/" version="3.2.0">
          <generator><name>Shearwater Cloud Desktop</name><version>2.0</version></generator>
          <gasdefinitions>
            <mix id="air"><name>Air</name><o2>0.21</o2><he>0.0</he></mix>
          </gasdefinitions>
          <profiledata>
            <repetitiongroup>
              <dive>
                <informationbeforedive><datetime>2026-04-15T10:00:00</datetime></informationbeforedive>
                <samples>
                  <waypoint>
                    <divetime>0</divetime><depth>0</depth>
                    <switchmix ref="air"/>
                    <divemode type="opencircuit"/>
                  </waypoint>
                  <waypoint>
                    <divetime>170</divetime><depth>11.19</depth>
                    <calculatedpo2>0.72</calculatedpo2>
                  </waypoint>
                </samples>
              </dive>
            </repetitiongroup>
          </profiledata>
        </uddf>
        """
        let data = Data(xml.utf8)
        let tree = try XMLTreeParser.parse(data: data)
        let interpreter = InterpreterFactory.interpreter(for: tree)
        #expect(String(describing: type(of: interpreter)).contains("Shearwater"),
                "expected Shearwater interpreter, got \(type(of: interpreter))")
        let result = try interpreter.interpret(tree: tree)

        let wp = result.document.dives.first?.waypoints.first { $0.calculatedPO2 != nil }
        #expect(wp != nil, "no waypoint with calculatedPO2 — dive parse failed?")
        if let po2 = wp?.calculatedPO2 {
            #expect(abs(po2 - 72_000) < 0.01,
                    "expected 72000 Pa, got \(po2)")
        }

        let ppo2Diags = result.diagnostics.filter {
            $0.level == .warning && $0.message.contains("calculatedpo2")
        }
        #expect(ppo2Diags.count == 1,
                "expected 1 warning for calculatedpo2, got \(ppo2Diags.count). All diags: \(result.diagnostics.map { "\($0.level): \($0.message)" })")
    }

    /// Spec-compliant PPO₂ must pass through unchanged and emit no
    /// diagnostic.
    @Test func standardInterpreter_compliantPO2Untouched() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <uddf xmlns="http://www.streit.cc/uddf/3.2/" version="3.2.0">
          <generator><name>SyntheticTest</name><version>1.0</version></generator>
          <gasdefinitions>
            <mix id="air"><name>Air</name><o2>0.21</o2><he>0.0</he></mix>
          </gasdefinitions>
          <profiledata>
            <repetitiongroup>
              <dive>
                <informationbeforedive><datetime>2026-04-15T10:00:00</datetime></informationbeforedive>
                <samples>
                  <waypoint>
                    <divetime>0</divetime><depth>0</depth>
                    <switchmix ref="air"/>
                    <divemode type="opencircuit"/>
                  </waypoint>
                  <waypoint>
                    <divetime>170</divetime><depth>11.19</depth>
                    <calculatedpo2>127000</calculatedpo2>
                  </waypoint>
                </samples>
              </dive>
            </repetitiongroup>
          </profiledata>
        </uddf>
        """
        let data = Data(xml.utf8)
        let tree = try XMLTreeParser.parse(data: data)
        let result = try StandardUDDFInterpreter().interpret(tree: tree)

        let wp = result.document.dives.first?.waypoints.first { $0.calculatedPO2 != nil }
        #expect(wp?.calculatedPO2 == 127_000)

        let ppo2Diags = result.diagnostics.filter {
            $0.message.contains("calculatedpo2")
        }
        #expect(ppo2Diags.isEmpty)
    }
}
