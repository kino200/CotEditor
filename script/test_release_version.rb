# 실제 fastlane 설정의 한국시간 빌드 번호 생성과 잘못된 입력 거부를 검증한다.
require "fastlane"
Fastlane.load_actions

fastfile = Fastlane::FastFile.new(File.expand_path("../fastlane/Fastfile", __dir__))

# 기대 버전 쌍과 함수 결과를 비교한다. 다르면 예외를 발생시키며 반환값은 없다.
def check_equal(expected, actual)
  raise "Unexpected release version: #{actual.inspect}" unless expected == actual
end

# 배포 함수와 오류 입력을 받아 실제 검증에서 거부되는지 확인한다.
def check_rejected(fastfile, options)
  begin
    fastfile.release_version(options)
  rescue FastlaneCore::Interface::FastlaneError
    return
  end
  raise "Invalid release option was accepted"
end

check_equal ["1.0.0", "01.02.0005"], fastfile.release_version({}, now: Time.utc(2026, 1, 1, 15, 5))
check_equal ["1.0.0", "11.17.1658"], fastfile.release_version({}, now: Time.utc(2026, 11, 17, 7, 58))
check_equal ["1.2.3", "02.29.0000"], fastfile.release_version({ version: "1.2.3", build_number: "02.29.0000" })
["2", "11.17.165", "1.02.0304", "00.01.0000", "13.01.1200", "04.31.0000", "02.30.1200", "11.17.2400", "11.17.1260", "../11.17.1200"].each do |value|
  check_rejected(fastfile, { build_number: value })
end
check_rejected(fastfile, { version: "../1", build_number: "11.17.1200" })
puts "Release version checks passed: 14 assertions."
