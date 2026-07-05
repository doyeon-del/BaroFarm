# BaroFarm(바로팜) — 신선식품 직거래 마켓 & 소상공인 스마트 물류 대시보드

> Spring Boot + MyBatis 기반 백엔드 CRUD와 Growth 데이터 분석 · AI 수요 예측을 결합한 2-Layer 아키텍처

[![Java](https://img.shields.io/badge/Java-17-007396?logo=openjdk&logoColor=white)](https://openjdk.org/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.3-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
![MyBatis](https://img.shields.io/badge/MyBatis-SQL_Mapper-B31B1B)
[![Vue](https://img.shields.io/badge/Vue.js-3-4FC08D?logo=vuedotjs&logoColor=white)](https://vuejs.org/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)](https://www.mysql.com/)
[![MongoDB](https://img.shields.io/badge/MongoDB-7.0-47A248?logo=mongodb&logoColor=white)](https://www.mongodb.com/)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-Dashboard-FF4B4B?logo=streamlit&logoColor=white)](https://streamlit.io/)

---

## 📌 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [2-Layer 아키텍처](#2-2-layer-아키텍처)
3. [기술 스택](#3-기술-스택)
4. [ERD 설계](#4-erd-설계-layer-1--rdb)
5. [행동 로그 스키마](#5-행동-로그-스키마-layer-2--nosql)
6. [REST API 명세](#6-rest-api-명세)
7. [화면 흐름 (User Flow)](#7-화면-흐름-user-flow)
8. [외부 데이터 파이프라인](#8-외부-데이터-파이프라인)
9. [Growth 분석 지표](#9-growth-분석-지표)
10. [AI 수요 예측 모델](#10-ai-수요-예측-모델)
11. [화면 구성 (Vue + Streamlit)](#11-화면-구성-vue--streamlit)
12. [프로젝트 구조](#12-프로젝트-구조)
13. [백엔드 1차 구현 범위](#13-백엔드-1차-구현-범위)
14. [로컬 실행 방법](#14-로컬-실행-방법)

---

## 1. 프로젝트 개요

**BaroFarm(바로팜)**은 소상공인(판매자)과 소비자를 연결하는 신선식품 직거래 마켓입니다.  
단순한 CRUD 웹 서비스를 넘어, **서비스에서 발생하는 모든 행동 데이터를 수집·분석·예측**하는 것이 핵심 목표입니다.

```
"데이터가 생성되는 순간부터 AI 예측까지, 전 과정을 직접 설계하고 구현한다."
```

### 핵심 목표

| 구분 | 목표 |
|------|------|
| **프론트엔드 기본 화면** | Vue 기반 소비자·판매자 서비스 화면 구현 |
| **백엔드 기본기** | Spring Boot + MyBatis 기반 회원·상품·주문·리뷰 CRUD |
| **Growth 분석** | 퍼널 전환율, 코호트 리텐션, A/B 테스트 통계 검정 |
| **AI 예측** | LSTM 기반 주간 발주량 예측 + 폐기율 경고 시스템 |
| **데이터 파이프라인** | 외부 API 배치 수집 → 분석 DB 적재 자동화 |

### 팀 · 역할 분담

**2인 팀 프로젝트** — SSAFY 서울 17반 관통 프로젝트

| 담당 | 역할 |
|------|------|
| **이도연** | 백엔드(Spring Boot · MyBatis · JWT 인증), 핵심 커머스 기능(멀티 판매처 가격비교 · 찜 · 마감임박 동적가격), 배포 인프라(Caddy · Docker Compose · Oracle Cloud VM · HTTPS), 데이터 분석 파이프라인(Growth KPI · Streamlit) |
| **이정원** | 판매자/관리자 분석 대시보드(Reflex), 공급망 AI 분석, 홈·배너 이미지 연동 |

**Live 배포**: [barofarm.duckdns.org](https://barofarm.duckdns.org)

---

## 2. 2-Layer 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│             Vue Frontend (B2C/B2B Service UI)                   │
└───────────────────────────┬─────────────────────────────────────┘
                            │ REST API (JSON)
┌───────────────────────────▼─────────────────────────────────────┐
│              LAYER 1 — Spring Boot Web Service                  │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  Auth API    │  │  Product API │  │     Order / Review API │ │
│  │  (JWT 인증)  │  │  (CRUD)      │  │     (전환 로그 생성)   │ │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬────────────┘ │
│         │                 │                      │              │
│  ┌──────▼─────────────────▼──────────────────────▼───────────┐ │
│  │              MySQL 8.0  (RDB — 운영 데이터)                │ │
│  │   USERS │ PRODUCTS │ ORDERS │ REVIEWS                     │ │
│  └───────────────────────────────────────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Event Log Filter (AOP / Interceptor)                   │   │
│  │  → 주요 요청에서 행동 이벤트를 추출해 로그 저장         │   │
│  └──────────────────────────┬──────────────────────────────┘   │
└─────────────────────────────│───────────────────────────────────┘
                              │ Direct Insert (Kafka는 추후 확장 옵션)
┌─────────────────────────────▼───────────────────────────────────┐
│              LAYER 2 — Data & AI Pipeline                       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  MongoDB  (행동 로그 — USER_BEHAVIOR_LOGS)              │   │
│  │  session_id · event_type · ab_test_group · product_id   │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │  Spring Batch (매일 새벽 2시)             │
│  ┌──────────────────▼──────────────────────────────────────┐   │
│  │  외부 데이터 수집 배치                                   │   │
│  │  KAMIS API │ 기상청 API │ 공휴일 API │ 네이버 DataLab   │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                           │
│  ┌──────────────────▼──────────────────────────────────────┐   │
│  │  Python AI Module  (LSTM / Prophet)                      │   │
│  │  · 다음 주 발주량 예측 (Demand Forecast)                 │   │
│  │  · 폐기 위험도 산출 (Spoilage Risk Score)               │   │
│  └──────────────────┬──────────────────────────────────────┘   │
│                     │                                           │
│  ┌──────────────────▼──────────────────────────────────────┐   │
│  │  Streamlit Analytics Dashboard                          │   │
│  │  · Growth 분석 / AI 예측 결과 시각화 (app.py)           │   │
│  │  · Vue 서비스 화면과 분리된 분석용 대시보드             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

> 초기 구현에서는 Kafka를 사용하지 않고 Spring Boot에서 MongoDB로 행동 로그를 직접 적재합니다.  
> Kafka는 대용량 트래픽 처리나 이벤트 스트리밍 확장이 필요할 때 도입할 수 있는 후속 개선 항목으로 둡니다.

---

## 3. 기술 스택

### Frontend (Service UI)

| 분류 | 기술 | 버전 | 용도 |
|------|------|------|------|
| Framework | Vue.js | 3.x | 소비자/판매자 기본 서비스 화면 |
| Router | Vue Router | 4.x | 페이지 라우팅 |
| HTTP Client | Axios | — | Spring Boot REST API 호출 |
| Chart | Chart.js 또는 ECharts | — | Vue 화면 내 간단한 KPI/차트 표시 |

### Backend (Layer 1)

| 분류 | 기술 | 버전 | 용도 |
|------|------|------|------|
| Language | Java | 17 | — |
| Framework | Spring Boot | 3.3.x | 웹 서버, REST API |
| SQL Mapper | MyBatis | 3.x | SQL Mapper 기반 RDB 접근 |
| Security | Spring Security + JWT | — | 인증/인가 |
| Database | MySQL | 8.0 | 운영 데이터 저장 |
| NoSQL | MongoDB | 7.0 | 행동 로그 적재 |
| Batch | Spring Batch | — | 외부 API 배치 수집 |
| Build | Gradle | 8.x | 빌드 도구 |
| Test | JUnit 5 + Mockito | — | 단위/통합 테스트 |
| Docs | Swagger (SpringDoc OpenAPI) | — | API 문서 자동화 |

### Data & AI (Layer 2)

| 분류 | 기술 | 용도 |
|------|------|------|
| Language | Python | 3.11 | 분석 및 모델링 |
| Dashboard | Streamlit | 대시보드 데모 |
| Visualization | Plotly | 인터랙티브 차트 |
| ML/DL | TensorFlow / Keras | LSTM 수요 예측 모델 |
| Time-Series | Prophet (Meta) | 계절성 분해 |
| Stats | SciPy | A/B 테스트 가설 검정 |
| Data | Pandas, NumPy | 데이터 전처리 |

---

## 4. ERD 설계 (Layer 1 — RDB)

```
┌──────────────────────┐         ┌──────────────────────────┐
│        USERS         │         │         PRODUCTS         │
├──────────────────────┤         ├──────────────────────────┤
│ user_id   BIGINT  PK │◄──┐     │ product_id  BIGINT    PK │
│ role      VARCHAR    │   │     │ seller_id   BIGINT    FK ├──► USERS
│ email     VARCHAR    │   │     │ name        VARCHAR      │
│ password  VARCHAR    │   │     │ description TEXT         │
│ name      VARCHAR    │   │     │ price       INT          │
│ created_at DATETIME  │   │     │ stock_qty   INT          │
└──────────────────────┘   │     │ thumbnail_url VARCHAR    │
                           │     │ ab_variant  VARCHAR      │   ← A/B 테스트 대상
                           │     │ created_at  DATETIME     │
                           │     │ updated_at  DATETIME     │
                           │     └──────────────────────────┘
                           │                  │
         ┌─────────────────┘                  │
         │                                    │
┌────────▼─────────────────────────────────────▼──────────┐
│                          ORDERS                          │
├──────────────────────────────────────────────────────────┤
│ order_id    BIGINT     PK                                │
│ buyer_id    BIGINT     FK ──────────────────► USERS      │
│ product_id  BIGINT     FK ──────────────────► PRODUCTS   │
│ quantity    INT                                          │
│ total_price INT                                          │
│ status      VARCHAR       ← 'COMPLETED' (Mock 결제)      │
│ order_date  DATETIME                                     │
└──────────────────────────┬───────────────────────────────┘
                           │
                ┌──────────▼──────────────────┐
                │          REVIEWS            │
                ├─────────────────────────────┤
                │ review_id   BIGINT     PK   │
                │ order_id    BIGINT     FK   │
                │ rating      INT   (1~5)     │
                │ content     TEXT            │
                │ created_at  DATETIME        │
                └─────────────────────────────┘
```

### DDL (MySQL)

```sql
CREATE TABLE users (
    user_id    BIGINT       NOT NULL AUTO_INCREMENT,
    role       VARCHAR(10)  NOT NULL COMMENT 'SELLER | BUYER',
    email      VARCHAR(100) NOT NULL UNIQUE,
    password   VARCHAR(255) NOT NULL,
    name       VARCHAR(50)  NOT NULL,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id)
);

CREATE TABLE products (
    product_id    BIGINT        NOT NULL AUTO_INCREMENT,
    seller_id     BIGINT        NOT NULL,
    name          VARCHAR(100)  NOT NULL,
    description   TEXT,
    price         INT           NOT NULL,
    stock_qty     INT           NOT NULL DEFAULT 0,
    thumbnail_url VARCHAR(500),
    ab_variant    VARCHAR(10)   COMMENT 'A | B  (썸네일 A/B 테스트용)',
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (product_id),
    FOREIGN KEY (seller_id) REFERENCES users (user_id)
);

CREATE TABLE orders (
    order_id    BIGINT      NOT NULL AUTO_INCREMENT,
    buyer_id    BIGINT      NOT NULL,
    product_id  BIGINT      NOT NULL,
    quantity    INT         NOT NULL DEFAULT 1,
    total_price INT         NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'COMPLETED',
    order_date  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id),
    FOREIGN KEY (buyer_id)   REFERENCES users (user_id),
    FOREIGN KEY (product_id) REFERENCES products (product_id)
);

CREATE TABLE reviews (
    review_id  BIGINT   NOT NULL AUTO_INCREMENT,
    order_id   BIGINT   NOT NULL UNIQUE,
    rating     INT      NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content    TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (review_id),
    FOREIGN KEY (order_id) REFERENCES orders (order_id)
);
```

### MyBatis 구현 기준

본 프로젝트의 운영 데이터 접근 방식은 **JPA가 아닌 MyBatis**를 기준으로 합니다.  
따라서 `Entity`와 `JpaRepository` 중심 구조가 아니라, **Domain/DTO + Mapper Interface + Mapper XML** 구조로 구현합니다.

```text
Controller → Service → Mapper Interface → Mapper XML → MySQL
```

#### 구현 단위 예시: Product

```text
src/main/java/com/freshgrowth/domain/product/
├── controller/ProductController.java
├── service/ProductService.java
├── mapper/ProductMapper.java
├── domain/Product.java
└── dto/
    ├── ProductCreateRequest.java
    ├── ProductUpdateRequest.java
    └── ProductResponse.java

src/main/resources/mapper/
└── ProductMapper.xml
```

#### 페이지네이션 기준

상품 목록 조회 API는 MyBatis에서 `LIMIT` / `OFFSET` 기반으로 구현합니다.

```http
GET /api/v1/products?page=0&size=10
```

```sql
SELECT product_id, seller_id, name, description, price, stock_qty, thumbnail_url, ab_variant, created_at, updated_at
FROM products
ORDER BY product_id DESC
LIMIT #{size} OFFSET #{offset};

SELECT COUNT(*)
FROM products;
```

Service 계층에서 `offset = page * size`를 계산하고, 목록 데이터와 전체 개수를 함께 반환합니다.

---

## 5. 행동 로그 스키마 (Layer 2 — NoSQL)

> Growth 분석(퍼널, 코호트)과 AI 수요 예측 피처의 원천 데이터입니다.  
> 확장성과 스키마 유연성을 위해 **MongoDB**에 적재합니다.

**Collection: `user_behavior_logs`**

| 필드 | 타입 | 설명 |
|------|------|------|
| `log_id` | String (UUID) | 로그 고유 식별자 |
| `timestamp` | DateTime | 이벤트 발생 시각 (시계열 모델링 필수 피처) |
| `user_id` | Long | 회원 ID (비로그인 시 `null` 허용) |
| `session_id` | String | 1회 방문 세션 ID — **퍼널 분석의 기준 키** |
| `event_type` | String | `view_home` · `click_product` · `view_detail` · `click_checkout` · `complete_order` |
| `product_id` | Long | 이벤트 대상 상품 ID |
| `ab_test_group` | String | `A_GROUP` (기존) · `B_GROUP` (신규) — 통계 검정용 |
| `device_type` | String | `PC_WEB` · `MOBILE_WEB` |
| `stay_duration` | Integer | 페이지 체류 시간(초) — 구매 의도 예측 피처 |

```json
// 샘플 도큐먼트
{
  "log_id"       : "550e8400-e29b-41d4-a716-446655440000",
  "timestamp"    : "2026-05-15T14:32:11.000Z",
  "user_id"      : 1042,
  "session_id"   : "sess_abc123",
  "event_type"   : "click_checkout",
  "product_id"   : 7,
  "ab_test_group": "B_GROUP",
  "device_type"  : "MOBILE_WEB",
  "stay_duration": 142
}
```

### 퍼널 이벤트 흐름

```
view_home ──► click_product ──► view_detail ──► click_checkout ──► complete_order
  10,000          6,500            4,200             1,800              1,080
  (100%)         (65.0%)          (42.0%)           (18.0%)            (10.8%)
```

> `session_id` 기준으로 이벤트 흐름을 추적하면 퍼널 전환율을 정확히 계산할 수 있습니다.

---

## 6. REST API 명세

> Swagger UI: `http://localhost:8080/swagger-ui.html`

### Auth

| Method | URI | 설명 |
|--------|-----|------|
| `POST` | `/api/v1/auth/signup` | 회원가입 (role: SELLER \| BUYER) |
| `POST` | `/api/v1/auth/login` | 로그인 → JWT 발급 |
| `POST` | `/api/v1/auth/refresh` | Access Token 재발급 |

### Products

| Method | URI | 설명 | 권한 |
|--------|-----|------|------|
| `GET` | `/api/v1/products` | 상품 목록 조회 (페이지네이션) | PUBLIC |
| `GET` | `/api/v1/products/{id}` | 상품 상세 조회 | PUBLIC |
| `POST` | `/api/v1/products` | 상품 등록 | SELLER |
| `PUT` | `/api/v1/products/{id}` | 상품 수정 | SELLER (본인) |
| `DELETE` | `/api/v1/products/{id}` | 상품 삭제 | SELLER (본인) |

### Orders

| Method | URI | 설명 | 권한 |
|--------|-----|------|------|
| `POST` | `/api/v1/orders` | 주문 생성 (Mock 결제) | BUYER |
| `GET` | `/api/v1/orders/my` | 내 주문 내역 조회 | BUYER |
| `GET` | `/api/v1/orders/seller` | 판매 내역 조회 | SELLER |

### Reviews

| Method | URI | 설명 | 권한 |
|--------|-----|------|------|
| `POST` | `/api/v1/reviews` | 리뷰 작성 | BUYER (구매 완료 건) |
| `GET` | `/api/v1/reviews/product/{id}` | 상품별 리뷰 목록 | PUBLIC |

### Growth Analytics (판매자 대시보드용)

| Method | URI | 설명 | 권한 |
|--------|-----|------|------|
| `GET` | `/api/v1/analytics/funnel` | 퍼널 전환율 조회 | SELLER |
| `GET` | `/api/v1/analytics/ab-test` | A/B 테스트 결과 | SELLER |
| `GET` | `/api/v1/analytics/demand-forecast` | AI 수요 예측값 | SELLER |
| `GET` | `/api/v1/analytics/spoilage-risk` | 폐기 위험 상품 목록 | SELLER |

---

## 7. 화면 흐름 (User Flow)

### B2C — 소비자 흐름

```
[홈 화면]
  · 상품 리스트 노출
  · A/B 테스트 배너 무작위 노출           LOG: view_home
       │
       ▼ 상품 클릭
[상품 상세 화면]
  · 상품 설명 / 가격 / 재고 / 리뷰         LOG: click_product, view_detail
       │
       ▼ 결제하기 클릭
[결제 완료 화면 (Mock)]
  · PG 연동 없이 status = 'COMPLETED'     LOG: click_checkout, complete_order
  · ORDERS 테이블 INSERT
       │
       ▼
[마이페이지]
  · 구매 내역 조회
  · 리뷰 작성 → REVIEWS 테이블 INSERT
```

### B2B — 판매자 흐름

```
[상품 관리]
  · 신선식품 등록 / 수정 / 삭제
  · 썸네일 업로드 (A/B 테스트 대상)

[스마트 물류 대시보드]  ← 포트폴리오 핵심
  ┌──────────────────────────────────────────┐
  │  KPI 요약  │  퍼널 분석  │  A/B 테스트  │
  │  AI 수요 예측 (시계열 차트)              │
  │  폐기 위험 상품 경고 테이블              │
  └──────────────────────────────────────────┘
```

---

## 8. 외부 데이터 파이프라인

> AI 수요 예측 모델의 정확도를 높이기 위해 공공 Open API 데이터를 배치로 수집합니다.  
> Spring Batch Job이 **매일 새벽 2시**에 실행되어 MySQL에 적재합니다.

### 수집 데이터 목록

| 데이터 | 제공 기관 | API / URL | 활용 목적 |
|--------|-----------|-----------|-----------|
| **농수산물 일별 도매가격** | aT 한국농수산식품유통공사 | [kamis.or.kr](https://www.kamis.or.kr) | 가격 급등 예측, 발주량 조정 인사이트 |
| **도매시장 거래 물량** | 농식품 빅데이터 거래소 | [nongnet.or.kr](https://www.nongnet.or.kr) | 산지 출하량 감소 → 재고 선제 대응 |
| **기상 관측 / 예보** | 기상청 | [data.kma.go.kr](https://data.kma.go.kr) | 강수·기온이 수요에 미치는 영향 모델링 |
| **공휴일 / 법정 특일** | 한국천문연구원 | [data.go.kr](https://www.data.go.kr) | 명절 전후 수요 급변 더미 변수 생성 |
| **키워드 검색량 트렌드** | Naver DataLab | [developers.naver.com](https://developers.naver.com) | 트렌드 선행 지표 → 수요 예측 피처 |

### 배치 파이프라인 흐름

```
Spring Batch Job (매일 02:00 KST)
        │
        ├─ Step 1: KAMIS API 호출 → 품목별 도매가 MySQL 적재
        │          (raw_wholesale_price 테이블)
        │
        ├─ Step 2: 기상청 API 호출 → 기상 데이터 MySQL 적재
        │          (raw_weather 테이블)
        │
        ├─ Step 3: 공휴일 API 호출 → 캘린더 피처 MySQL 적재
        │          (raw_calendar 테이블)
        │
        ├─ Step 4: Naver DataLab API 호출 → 검색량 지수 MySQL 적재
        │          (raw_search_trend 테이블)
        │
        └─ Step 5: Python AI 모듈 호출 (REST 또는 subprocess)
                   → 수요 예측값 + 폐기 위험도 → MySQL 적재
                      (demand_forecast 테이블)
```

### 수집 가능한 공개 데이터 현황

| 데이터 | 과거 기간 | 무료 여부 | 갱신 주기 |
|--------|-----------|-----------|-----------|
| KAMIS 도매가격 | ~3년 | 무료 (API 키 발급) | 일별 |
| 기상청 ASOS 관측 | ~30년 | 무료 | 시간별 |
| 기상청 단기예보 | 3일 예보 | 무료 | 3시간 |
| 공휴일 정보 | 연도별 | 무료 | 연간 |
| Naver DataLab | ~3년 | 무료 (API 키) | 일별 |
| 농산물 도매 물량 | ~2년 CSV | 무료 | 일별 |

---

## 9. Growth 분석 지표

### 퍼널 전환율 (Funnel)

`session_id` 기준으로 각 단계의 전환율을 계산합니다.

```sql
-- 일별 퍼널 전환율 쿼리 (MongoDB Aggregation 예시)
db.user_behavior_logs.aggregate([
  { $match: { timestamp: { $gte: ISODate("2026-05-09") } } },
  { $group: {
      _id: "$event_type",
      unique_sessions: { $addToSet: "$session_id" }
  }},
  { $project: {
      event_type: "$_id",
      count: { $size: "$unique_sessions" }
  }}
])
```

### A/B 테스트 — 통계적 가설 검정

- **귀무가설 H₀**: 두 그룹(A, B)의 구매 전환율에 차이가 없다.  
- **대립가설 H₁**: B 그룹의 전환율이 A 그룹보다 높다.  
- **검정 방법**: 양측 Z-검정 (표본 수 ≥ 1,000 충족 시)  
- **유의수준**: α = 0.05

```
A안: 노출 5,000회 → 전환 210건 (4.20%)
B안: 노출 5,200회 → 전환 302건 (5.81%)
Z-통계량: 4.872 | p-value: 0.0000 → H₀ 기각 ✅
```

### 코호트 리텐션

가입 주차 기준으로 N주 후 재구매 여부를 추적합니다.

```
          Week 0  Week 1  Week 2  Week 3  Week 4
Cohort 1  100%    68%     45%     32%     24%
Cohort 2  100%    71%     48%     35%     —
Cohort 3  100%    65%     —       —       —
```

---

## 10. AI 수요 예측 모델

### 입력 피처 (Feature)

| 피처 그룹 | 피처 예시 |
|-----------|-----------|
| 내부 행동 로그 | 일별 `click_product` 수, `complete_order` 수, 상품별 체류 시간 |
| 내부 판매 데이터 | 과거 28일 일별 판매량, 재고 소진율 |
| 외부 기상 | 기온, 강수량, 강수 여부 (0/1) |
| 외부 가격 | 전날 도매가격, 전주 대비 가격 변동률 |
| 캘린더 | 요일 (0~6), 공휴일 여부, 명절 D-Day |
| 트렌드 | 품목별 Naver 검색 지수 |

### 모델 구조 (LSTM)

```
Input  → [28일 × 피처 수] Sliding Window
       → LSTM (128 units) → Dropout(0.2)
       → LSTM (64 units)  → Dropout(0.2)
       → Dense (7)         ← 다음 7일 예측값
Output → 일별 예상 발주량 (kg)
```

### 폐기 위험도 산출

```
폐기 예상량 = 현재 재고 - AI 예측 수요
폐기 위험도 = HIGH   (유통기한 ≤ 2일 AND 폐기 예상량 > 5kg)
            = MEDIUM (유통기한 ≤ 4일 AND 폐기 예상량 > 0kg)
            = LOW    (그 외)
```

---

## 11. 화면 구성 (Vue + Streamlit)

이 프로젝트의 화면은 **Vue 서비스 화면**과 **Streamlit 분석 대시보드**로 역할을 분리합니다.

| 구분 | 기술 | 목적 | 주요 사용자 |
|------|------|------|-------------|
| 기본 서비스 화면 | Vue.js | 상품 조회, 주문, 리뷰, 상품 관리 등 실제 서비스 흐름 구현 | 소비자, 판매자 |
| 분석 대시보드 | Streamlit | 행동 로그와 주문 데이터를 기반으로 Growth 분석·AI 예측 결과 시각화 | 판매자, 분석가, 평가자 |

### Vue — 기본 서비스 화면

Vue는 사용자가 실제로 이용하는 마켓 화면을 담당합니다. Vue는 MySQL에 직접 접근하지 않고, Spring Boot REST API를 호출해 데이터를 주고받습니다.

#### 소비자(B2C) 화면

- **홈/상품 목록**: 상품 카드, 카테고리 필터, 페이지네이션
- **상품 상세**: 상품 설명, 가격, 재고, 리뷰 조회
- **주문/결제 완료 Mock**: 결제 연동 없이 주문 생성 API 호출
- **마이페이지**: 내 주문 내역 조회
- **리뷰 작성**: 구매 완료 주문에 대한 리뷰 등록

#### 판매자(B2B) 화면

- **상품 관리**: 상품 등록, 수정, 삭제, 내 상품 목록 조회
- **판매 내역 조회**: 주문 현황 및 판매 상품 확인
- **간단 KPI 영역**: 오늘 주문 수, 매출, 재고 부족 상품 등 기본 지표 표시

### Streamlit — 데이터 분석/AI 대시보드

Streamlit은 실제 서비스 화면이 아니라, DA/DE 포트폴리오를 위한 분석 결과 시각화 화면입니다.

| 파일 | 대상 | 실행 명령 |
|------|------|-----------|
| `app.py` | Growth 분석 및 AI 예측 대시보드 | `streamlit run app.py` |

#### Streamlit 대시보드 구성

- **KPI 요약**: 오늘 매출 / 방문자 수 / 전환율 / 재고
- **퍼널 분석**: `view_home → click_product → view_detail → click_checkout → complete_order` 전환율
- **A/B 테스트**: 썸네일 또는 배너 실험군별 전환율 비교와 통계 검정
- **AI 수요 예측**: 실적(실선) + 예측(점선) 시계열 차트
- **폐기 위험 테이블**: 유통기한과 예측 수요 기반 위험 상품 목록

### 화면 구현 우선순위

| 우선순위 | 화면/기능 | 기술 | 설명 |
|----------|-----------|------|------|
| 1 | 상품 목록/상세 | Vue + Spring API | Product CRUD와 가장 먼저 연결 |
| 2 | 상품 등록/수정 | Vue + Spring API | 판매자 기본 기능 구현 |
| 3 | 주문 생성/내역 | Vue + Spring API | 소비자 구매 플로우 구현 |
| 4 | 리뷰 작성/조회 | Vue + Spring API | 주문 이후 사용자 행동 완성 |
| 5 | 분석 대시보드 | Streamlit | 로그/주문 데이터 기반 분석 시각화 |


---

## 12. 프로젝트 구조

```
ssarak_store/
│
├── frontend/                              # Vue 서비스 화면
│   ├── src/
│   │   ├── api/                           # Axios API 모듈
│   │   ├── router/                        # Vue Router 설정
│   │   ├── views/
│   │   │   ├── ProductListView.vue
│   │   │   ├── ProductDetailView.vue
│   │   │   ├── SellerProductManageView.vue
│   │   │   ├── OrderCompleteView.vue
│   │   │   └── MyPageView.vue
│   │   └── components/
│   ├── package.json
│   └── vite.config.js
│
├── src/                                   # Spring Boot 소스
│   └── main/
│       ├── java/com/freshgrowth/
│       │   ├── FreshGrowthApplication.java
│       │   ├── domain/
│       │   │   ├── user/
│       │   │   │   ├── controller/AuthController.java
│       │   │   │   ├── service/UserService.java
│       │   │   │   ├── mapper/UserMapper.java
│       │   │   │   ├── domain/User.java
│       │   │   │   └── dto/
│       │   │   ├── product/
│       │   │   │   ├── controller/ProductController.java
│       │   │   │   ├── service/ProductService.java
│       │   │   │   ├── mapper/ProductMapper.java
│       │   │   │   ├── domain/Product.java
│       │   │   │   └── dto/
│       │   │   │       ├── ProductCreateRequest.java
│       │   │   │       ├── ProductUpdateRequest.java
│       │   │   │       └── ProductResponse.java
│       │   │   ├── order/
│       │   │   │   ├── controller/OrderController.java
│       │   │   │   ├── service/OrderService.java
│       │   │   │   ├── mapper/OrderMapper.java
│       │   │   │   ├── domain/Order.java
│       │   │   │   └── dto/
│       │   │   └── review/
│       │   │       ├── controller/ReviewController.java
│       │   │       ├── service/ReviewService.java
│       │   │       ├── mapper/ReviewMapper.java
│       │   │       ├── domain/Review.java
│       │   │       └── dto/
│       │   ├── log/
│       │   │   ├── document/UserBehaviorLog.java   # MongoDB Document
│       │   │   ├── repository/BehaviorLogRepository.java
│       │   │   └── interceptor/EventLogInterceptor.java
│       │   ├── analytics/
│       │   │   ├── service/FunnelAnalyticsService.java
│       │   │   ├── service/AbTestService.java
│       │   │   └── controller/AnalyticsController.java
│       │   ├── batch/
│       │   │   ├── KamisApiBatchJob.java           # 농산물 도매가 수집
│       │   │   ├── WeatherApiBatchJob.java          # 기상 데이터 수집
│       │   │   └── DemandForecastBatchJob.java      # AI 예측값 적재
│       │   └── global/
│       │       ├── config/SecurityConfig.java
│       │       ├── config/MongoConfig.java
│       │       ├── jwt/JwtTokenProvider.java
│       │       └── exception/GlobalExceptionHandler.java
│       └── resources/
│           ├── mapper/
│           │   ├── UserMapper.xml
│           │   ├── ProductMapper.xml
│           │   ├── OrderMapper.xml
│           │   └── ReviewMapper.xml
│           ├── application.yml
│           └── application-local.yml
│
├── app.py                                 # Growth 분석 및 AI 예측 대시보드 (Streamlit)
└── README.md
```

---

## 13. 백엔드 1차 구현 범위

초기 구현에서는 전체 아키텍처를 한 번에 만들지 않고, **MyBatis 기반 운영 데이터 CRUD**부터 구현합니다.

### 1차 목표

| 우선순위 | 기능 | 설명 |
|----------|------|------|
| 1 | DB 연결 | MySQL 연결 및 DDL 실행 |
| 2 | 상품 CRUD | 상품 등록, 목록 조회, 상세 조회, 수정, 삭제 |
| 3 | 페이지네이션 | `page`, `size` 기반 상품 목록 조회 |
| 4 | Vue 상품 화면 연결 | 상품 목록/상세 화면에서 Spring API 호출 |
| 5 | 주문 생성 | Mock 결제 기준 주문 데이터 저장 |
| 6 | 리뷰 작성 | 구매 완료 주문에 대한 리뷰 저장 |

### 후순위 확장

| 기능 | 진행 시점 |
|------|-----------|
| JWT 인증 / Spring Security | 기본 CRUD 안정화 이후 |
| CORS 설정 | 프론트엔드와 실제 연결할 때 |
| MongoDB 행동 로그 | 상품/주문 흐름 구현 이후 |
| Analytics API | 행동 로그가 쌓인 이후 |
| Spring Batch / 외부 API | 핵심 서비스 API 구현 이후 |
| AI 수요 예측 연동 | 분석용 데이터 구조 확정 이후 |

---

## 14. 로컬 실행 방법

### 사전 요구사항

- Java 17+
- MySQL 8.0
- MongoDB 7.0
- Node.js 20+ (Vue 프론트엔드 실행용)
- Python 3.11+ (Streamlit 분석 대시보드용)

### 1. DB 설정

```bash
# MySQL
mysql -u root -p
CREATE DATABASE freshgrowth CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# MongoDB — 별도 설정 불필요 (Spring Boot 자동 생성)
```

### 2. 환경변수 설정 (`application-local.yml`)

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/freshgrowth
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
    driver-class-name: com.mysql.cj.jdbc.Driver
  data:
    mongodb:
      uri: mongodb://localhost:27017/freshgrowth_logs

mybatis:
  mapper-locations: classpath:mapper/*.xml
  type-aliases-package: com.freshgrowth.domain
  configuration:
    map-underscore-to-camel-case: true

external:
  kamis:
    api-key: ${KAMIS_API_KEY}
  weather:
    api-key: ${KMA_API_KEY}
  naver:
    client-id: ${NAVER_CLIENT_ID}
    client-secret: ${NAVER_CLIENT_SECRET}
```

### 3. Spring Boot 실행

```bash
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 4. Vue 프론트엔드 실행

```bash
cd frontend
npm install
npm run dev
```

### 5. Streamlit 분석 대시보드 실행

```bash
# 의존성 설치
pip install streamlit pandas numpy plotly scipy

# Growth 분석 및 AI 예측 대시보드
streamlit run app.py
```

---


## 라이선스

This project is for **portfolio purposes only**.  
Initial data used in Streamlit dashboard demos may be simulated Mock Data.

---

