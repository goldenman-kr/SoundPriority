# SoundPriority

메뉴 바에서 간편하게 시스템 오디오 출력 장치를 우선순위에 따라 자동 전환하는 macOS 네이티브 애플리케이션입니다.

## 📋 목차

- [개요](#개요)
- [주요 기능](#주요-기능)
- [프로젝트 구조](#프로젝트-구조)
- [핵심 컴포넌트](#핵심-컴포넌트)
- [기술 스택](#기술-스택)
- [아키텍처](#아키텍처)
- [설치 및 빌드](#설치-및-빌드)
- [사용 방법](#사용-방법)
- [핵심 개념](#핵심-개념)
- [개발 가이드](#개발-가이드)

## 개요

SoundPriority는 macOS의 메뉴 바에서 실행되는 경량 애플리케이션으로, 사용자가 설정한 우선순위에 따라 현재 연결된 오디오 장치(스피커, 헤드폰, AirPods 등) 중 가장 우선순위가 높은 장치를 자동으로 시스템 기본 출력으로 설정합니다.

### 핵심 사용 사례

- 여러 Bluetooth 장치 간 자동 전환
- 충전 스테이션 연결 시 외장 스피커로 자동 변경
- 외출 시 노트북 스피커로 자동 복구
- USB 오디오 인터페이스와 내장 스피커 간 자동 전환

## 주요 기능

- 🔄 **자동 전환**: 1초마다 현재 연결된 장치 확인 및 우선순위가 가장 높은 장치로 자동 전환
- ⚙️ **우선순위 관리**: 사용자 정의 우선순위 목록 설정 및 드래그앤드롭으로 순서 변경
- 📌 **메뉴 바 통합**: 항상 접근 가능한 메뉴 바 아이콘
- 💾 **오프라인 기기 기억**: 연결이 끊긴 장치도 목록에 유지하여 재연결 시 우선순위 보존
- 🚀 **로그인 시 자동 실행**: "Launch at Login" 옵션으로 시스템 시작 시 자동 실행
- 🪟 **설정 윈도우**: 각 기기의 연결 상태 확인 및 우선순위 관리 UI
- 💡 **현재 출력 표시**: 설정 윈도우에서 현재 활성 출력 장치 실시간 표시

## 프로젝트 구조

```
SoundPriority/
├── README.md                      # 프로젝트 문서 (현재 파일)
└── SoundPriority/
    ├── SoundPriority/             # 소스 코드 디렉토리
    │   ├── SoundPriorityApp.swift # 애플리케이션 진입점 & SceneKit 설정
    │   ├── AppDelegate.swift      # 애플리케이션 라이프사이클 & 메뉴 바 초기화
    │   ├── AppState.swift         # 중앙 상태 관리 & 데이터 지속성
    │   ├── AudioDeviceManager.swift # Core Audio 래퍼 & 장치 관리
    │   ├── PriorityResolver.swift # 우선순위 기반 장치 선택 로직
    │   ├── StatusBarController.swift # 메뉴 바 UI 제어
    │   ├── MenuBarPopoverView.swift # 메뉴 바 팝오버 UI
    │   ├── SettingsView.swift     # 설정 윈도우 UI
    │   ├── LaunchAtLoginManager.swift # 로그인 시 자동 실행 관리
    │   └── Assets.xcassets/       # 이미지 자산 (앱 아이콘, 메뉴 바 아이콘)
    └── SoundPriority.xcodeproj/   # Xcode 프로젝트 설정
```

## 핵심 컴포넌트

### 1. **SoundPriorityApp.swift** - 애플리케이션 진입점
- `@main` 구조체로 SwiftUI 앱 라이프사이클 관리
- Settings 윈도우 Scene 정의
- 현재 앱의 핵심 UI 컴포넌트 관리

### 2. **AppDelegate.swift** - 애플리케이션 라이프사이클
- 앱 시작 시 상태 초기화
- 메뉴 바 아이콘 및 팝오버 설정
- 1초 간격 폴링 시작

### 3. **AppState.swift** - 중앙 상태 관리
```
책임:
- 현재 연결된 모든 오디오 출력 장치 목록 유지
- 사용자 정의 우선순위 순서 저장
- 자동 전환 토글 상태 관리
- UserDefaults를 통한 상태 지속성

주요 속성:
- outputDevices: 현재 연결된 장치 배열
- defaultOutputDeviceID: 시스템 기본 출력 장치 ID
- priorityOrder: 사용자 설정 우선순위 (UID 배열)
- lastSeenDeviceNames: 장치 UID별 마지막 알려진 이름 (오프라인 표시용)
- autoSwitchEnabled: 자동 전환 활성화 여부
```

### 4. **AudioDeviceManager.swift** - Core Audio 통합
```
책임:
- Core Audio HAL을 통해 시스템 오디오 장치 열거
- 현재 기본 출력 장치 조회
- 기본 출력 장치 설정

핵심 API:
- getOutputDevices() -> [AudioDevice]: 현재 연결된 출력 장치 목록
- getDefaultOutputDeviceID() -> AudioDeviceID: 현재 기본 출력 장치 ID
- setDefaultOutputDevice(id:) -> Bool: 기본 출력 장치 설정

AudioDevice 구조:
- id: UInt32 - 일시적 장치 식별자 (연결 해제 시 변경됨)
- uid: String - 안정적인 UID (Bluetooth 주소 등, 재연결 후에도 유지)
- name: String - 사용자 친화적 이름
```

### 5. **PriorityResolver.swift** - 우선순위 기반 선택
```
책임:
- 사용자 우선순위 목록에서 현재 연결된 장치 중 가장 우선순위가 높은 것을 선택

로직:
1. availableDevices를 uid별로 딕셔너리로 변환
2. priorityOrder를 순회하며 딕셔너리에서 일치하는 장치 찾기
3. 찾은 첫 번째 장치 반환 (가장 높은 우선순위)

UID 기반 매칭의 장점:
- 장치 재연결 후 같은 UID면 자동 인식
- 네트워크 오디오 장치도 안정적으로 추적
- 일시적 ID 변경에 영향받지 않음
```

### 6. **StatusBarController.swift** - 메뉴 바 UI 제어
```
책임:
- NSStatusItem을 통해 메뉴 바에 아이콘 표시
- NSPopover를 통해 클릭 시 메뉴 표시
- 템플릿 이미지 사용으로 다크 모드 자동 지원

상호작용:
- 메뉴 바 아이콘 클릭 시 팝오버 토글
- 팝오버 밖 클릭 시 자동 닫기
```

### 7. **MenuBarPopoverView.swift** - 메뉴 바 팝오버 UI
```
책임:
- 메뉴 바 팝오버에 표시되는 빠른 접근 메뉴
- 현재 출력 장치 표시
- Settings 윈도우 열기 버튼
```

### 8. **SettingsView.swift** - 설정 윈도우 UI
```
책임:
- 프로젝트 우선순위 목록 표시 (연결됨/연결 끊김 상태 구분)
- 우선순위 드래그앤드롭으로 쉽게 변경
- 연결 끊긴 기기 삭제
- 자동 전환 토글
- 로그인 시 자동 실행 토글

UI 요소:
- Toggle: Auto-switch 활성화
- Toggle: Launch at Login
- 현재 출력 장치 표시
- 우선순위 목록 (드래그 가능)
- 연결/미연결 상태 표시
```

### 9. **LaunchAtLoginManager.swift** - 로그인 시 자동 실행
```
책임:
- SMAppService를 통해 로그인 시 자동 실행 설정 관리
- 상태 조회 및 토글
- 오류 처리 및 사용자 알림
```

## 기술 스택

- **언어**: Swift
- **UI 프레임워크**: SwiftUI
- **오디오 API**: Core Audio (AudioToolbox)
- **시스템 통합**: AppKit (메뉴 바, 팝오버)
- **빌드 시스템**: Xcode 16+
- **최소 OS**: macOS 13.0+
- **상태 관리**: @Observable (SwiftUI)
- **데이터 지속성**: UserDefaults
- **로그인 자동 실행**: SMAppService

## 아키텍처

### 계층 구조

```
┌─────────────────────────────────────────┐
│          UI Layer (SwiftUI)             │
│  ├─ SoundPriorityApp (SceneKit)         │
│  ├─ SettingsView (설정 윈도우)          │
│  └─ MenuBarPopoverView (메뉴 바 팝오버) │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│     AppKit Layer (macOS 통합)           │
│  ├─ AppDelegate (라이프사이클)          │
│  └─ StatusBarController (메뉴 바)       │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│       Business Logic Layer              │
│  ├─ AppState (상태 관리)                │
│  ├─ PriorityResolver (선택 로직)        │
│  └─ LaunchAtLoginManager (자동 실행)    │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│    Core Audio Layer (macOS 시스템)      │
│  └─ AudioDeviceManager (HAL 래퍼)       │
└─────────────────────────────────────────┘
```

### 데이터 흐름

```
1. 폴링 주기 (1초마다):
   ┌─────────────────────────────────────────────────┐
   │ 1. AudioDeviceManager.getOutputDevices()        │ (Core Audio)
   │    → 현재 연결된 모든 장치 조회                  │
   ├─────────────────────────────────────────────────┤
   │ 2. AppState.outputDevices 업데이트              │ (상태 관리)
   ├─────────────────────────────────────────────────┤
   │ 3. PriorityResolver.resolve() 실행              │ (비즈니스 로직)
   │    → 우아 양험순위 기반 최고 우선순위 장치 선택  │
   ├─────────────────────────────────────────────────┤
   │ 4. AudioDeviceManager.setDefaultOutputDevice()  │ (Core Audio)
   │    → 선택된 장치로 시스템 기본 출력 설정         │
   └─────────────────────────────────────────────────┘

2. 사용자 상호작용 (설정 변경):
   ┌─────────────────────────────────────────────────┐
   │ 1. SettingsView에서 우선순위 변경               │ (UI)
   ├─────────────────────────────────────────────────┤
   │ 2. AppState.priorityOrder 업데이트              │ (상태 관리)
   ├─────────────────────────────────────────────────┤
   │ 3. UserDefaults에 자동 저장                     │ (지속성)
   ├─────────────────────────────────────────────────┤
   │ 4. 다음 폴링 주기에 새로운 우선순위 적용        │ (자동 전환)
   └─────────────────────────────────────────────────┘
```

### 상태 관리

- **@Observable**: AppState는 SwiftUI의 @Observable 매크로 사용
- **Reactive 업데이트**: 상태 변경 시 자동으로 UI 갱신
- **UserDefaults 지속성**: priorityOrder, lastSeenDeviceNames, autoSwitchEnabled 자동 저장
- **싱글톤 패턴**: AppState.shared로 애플리케이션 전역 접근

## 설치 및 빌드

### 요구사항

- macOS 13.0 이상
- Xcode 16.0 이상
- Apple 개발자 계정 (선택사항, 서명 없이도 실행 가능)

### 빌드 방법

1. **저장소 클론**
```bash
git clone https://github.com/goldenman-kr/SoundPriority.git
cd SoundPriority
```

2. **Xcode에서 열기**
```bash
open SoundPriority/SoundPriority.xcodeproj
```

3. **빌드**
```bash
xcodebuild -scheme SoundPriority -configuration Release build
```

4. **런 (개발 모드)**
- Xcode에서 ▶️ (Run) 버튼 클릭 또는 `Cmd+R`

### 앱 자동 실행 설정

로그인 시 자동 실행을 위해서는:
1. 앱 실행 후 Settings 윈도우 열기
2. "Launch at Login" 토글 활성화

SMAppService가 자동으로 로그인 항목에 등록합니다.

## 사용 방법

### 기본 사용법

1. **앱 실행**: 애플리케이션 시작 시 메뉴 바에 아이콘 표시
2. **메뉴 바 아이콘 클릭**: 빠른 접근 메뉴 표시
3. **Settings 열기**: 팝오버에서 "Settings" 버튼 클릭
4. **우선순위 설정**: 
   - Settings 윈도우에서 장치 목록 확인
   - 원하는 순서대로 드래그앤드롭으로 재정렬
5. **자동 전환 활성화**: "Auto-switch to highest priority device" 토글

### 우선순위 목록 이해

**상태별 표시**:
- ✓ 패시 (오른쪽): 현재 연결된 장치
- ⚠️ 회색글자: 연결이 끊긴 장치 (재연결 시 우선순위 유지)
- 볼드글자: 현재 시스템 기본 출력 장치

**장치 추가/제거**:
- 새 장치 연결 시 자동으로 목록에 추가
- 연결 끊긴 장치 항목을 좌측으로 스와이프하면 목록에서 제거

### 실제 사용 예시

**시나리오**: 회사에서 집으로 이동하는 경우
```
설정된 우선순위:
1. AirPods Pro (회사에서 연결 가능)
2. USB 스피커 (회사 책상)
3. MacBook 스피커

상황:
- 회사: AirPods Pro 자동 선택
- 충전 스테이션에 도킹: USB 스피커 자동 선택
- 집 반환(AirPods 끔): MacBook 스피커 자동 선택
```

## 핵심 개념

### UID vs ID

- **ID (UInt32)**: 일시적 장치 식별자
  - 장치 연결/해제 시 변경 가능
  - Core Audio API에서 사용
  - 현재 세션에서만 유효

- **UID (String)**: 안정적인 고유 식별자
  - Bluetooth 주소, MAC 주소 등
  - 재연결 후에도 유지
  - 우선순위 저장에 사용
  - 장치별 매칭의 기반

**예시**:
```
장치 연결 (첫 접속):
- id: 42, uid: "48-8F-5A-12-34-56", name: "AirPods Pro"

장치 해제 후 재연결:
- id: 127, uid: "48-8F-5A-12-34-56", name: "AirPods Pro"
                ↑ 같음 (자동 인식됨)
```

### 폴링 메커니즘

- **주기**: 1초마다
- **목적**: 장치 연결/해제 감지 및 우선순위 기반 자동 전환
- **성능**: 경량 쿼리이므로 배터리 영향 미미
- **시작**: AppDelegate.applicationDidFinishLaunching()에서 시작
- **중단**: 앱 인활성화 시 잠시 중단 (선택사항)

### UserDefaults 저장 키

| 키 | 보관 내용 | 형식 |
|---|---------|------|
| `audioPriority.devicePriorityOrder` | 우선순위 목록 | `[String]` (UID 배열) |
| `audioPriority.deviceDisplayNames` | 장치명 기록 | `[String: String]` (UID → 이름) |
| `audioPriority.autoSwitchEnabled` | 자동 전환 활성화 | `Bool` |

## 개발 가이드

### 새로운 기능 추가

#### 1. 새로운 출력 장치 필터 추가 (예: 특정 제조사 제외)

**파일**: AudioDeviceManager.swift
```swift
// isOutputDevice 수정
func isOutputDevice(deviceID: AudioDeviceID) -> Bool {
    // 기존 로직 + 새 필터
    let uid = getDeviceUID(deviceID: deviceID)
    let blacklistedFirmware = [/* ... */]
    guard !blacklistedFirmware.contains(uid) else { return false }
    return true
}
```

#### 2. 우선순위 자동 설정 기능 추가

**파일**: AppState.swift
```swift
func suggestPriorityOrder(basedOn devices: [AudioDevice]) {
    // 장치 유형별로 자동으로 우선순위 정렬
    let sorted = devices.sorted { $0.name < $1.name }
    self.priorityOrder = sorted.map { $0.uid }
}
```

#### 3. 의견 처리 추가 (예: 활동 로그)

**파일**: PriorityResolver.swift
```swift
static func resolve(
    availableDevices: [AudioDevice],
    priorityOrder: [String],
    log: (String) -> Void = { _ in }
) -> AudioDevice? {
    // ... 기존 로직 ...
    if let device = byUID[uid] {
        log("Switching to \(device.name)")
        return device
    }
}
```

### 버그 수정

#### 일반적인 문제 및 해결책

| 문제 | 원인 | 해결책 |
|------|------|--------|
| 자동 전환이 작동하지 않음 | autoSwitchEnabled == false | SettingsView에서 토글 확인 |
| 일부 장치가 나타나지 않음 | Core Audio 권한 문제 | 시스템 설정 → 개인정보보호 확인 |
| 재연결 후 우선순위 유지 안 됨 | UID 불일치 | AudioDeviceManager에서 UID 로직 확인 |
| 메뉴 바 아이콘 안 보임 | 아이콘 템플릿 설정 누락 | StatusBarController의 image.isTemplate 확인 |

### 테스트

#### Unit Test 예시 (PriorityResolver)

```swift
import XCTest

class PriorityResolverTests: XCTestCase {
    
    func testResolvesHighestPriorityDevice() {
        let devices = [
            AudioDevice(id: 1, uid: "device-a", name: "Device A"),
            AudioDevice(id: 2, uid: "device-b", name: "Device B"),
        ]
        let priority = ["device-b", "device-a"]
        
        let result = PriorityResolver.resolve(
            availableDevices: devices,
            priorityOrder: priority
        )
        
        XCTAssertEqual(result?.uid, "device-b")
    }
    
    func testReturnsNilWhenNoDeviceAvailable() {
        let result = PriorityResolver.resolve(
            availableDevices: [],
            priorityOrder: ["device-a"]
        )
        
        XCTAssertNil(result)
    }
}
```

#### 수동 테스트

1. **다중 장치 연결/해제**
   - Bluetooth 장치 여러 개 연결하여 우선순위 변경 테스트
   
2. **앱 재시작**
   - 앱 종료 후 재시작 시 설정이 유지되나 확인
   
3. **로그인 시 자동 실행**
   - 로그아웃 후 로그인하여 자동 시작 확인
   
4. **다크/라이트 모드**
   - macOS 테마 전환 시 메뉴 바 아이콘 정상 표시 확인

### 코드 스타일

- **네이밍**: camelCase (변수), PascalCase (클래스/구조체)
- **주석**: 각 함수/클래스 위에 목적 설명
- **상수**: MARK 주석으로 섹션 구분
- **에러 처리**: try-catch 또는 옵셔널 체이닝 사용

---

## 라이센스

이 프로젝트는 특정 라이센스 하에 배포됩니다. 자세한 내용은 LICENSE 파일을 참고하세요.

## 기여

버그 리포트, 기능 제안, 코드 기여는 항상 환영합니다!

---

**작성일**: 2026년 3월 20일