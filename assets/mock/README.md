개발용 Naver API 응답 샘플이 들어 있는 폴더입니다. 네트워크 상태와 무관하게 파싱 / UI 작업을 진행하기 위해 저장해 두었습니다.

## 파일

| 파일 | 원본 endpoint | 비고 |
| --- | --- | --- |
| `autocomplete_samsung.json` | `GET https://ac.stock.naver.com/ac?q=삼성&target=stock,ipo,index,marketindicator` | 여러 종목이 매칭되는 일반 케이스 |
| `autocomplete_kakao.json` | 같은 endpoint, `q=카카오` | 다른 검색어 케이스 |
| `autocomplete_empty.json` | 같은 endpoint, `q=zzzzzzzz` | `items` 가 비어 있는 케이스 |
| `realtime_quotes.json` | `GET https://polling.finance.naver.com/api/realtime?query=SERVICE_ITEM:005930,000660,035420,035720,207940,051910` | 관심종목 다건을 한 번에 조회한 응답 |
| `meta_{symbol}.json` | `GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}` | 6개 심볼 (`005930`, `000660`, `035420`, `035720`, `207940`, `051910`) |
| `sise_day_005930_p1.html` … `_p3.html` | `GET https://finance.naver.com/item/sise_day.naver?code=005930&page={1..3}` | 페이지네이션이 필요한 일별 시세 HTML 3페이지 |
| `sise_day_000660_p1.html` | 같은 endpoint, `code=000660&page=1` | 다른 종목의 1페이지 |

## 인코딩

- 자동완성 / 메타는 UTF-8 JSON 입니다.
- 실시간 시세는 `Content-Type` 이 `text/plain;charset=EUC-KR` 로 옵니다.
- 일별 시세 HTML 도 EUC-KR 입니다.

저장할 때 CP949 → UTF-8 로 재저장해 두었기 때문에, 앱에서는 `rootBundle.loadString` 으로 바로 읽으실 수 있습니다. 실제 endpoint 를 직접 호출하는 경로에서는 `bodyBytes` 를 EUC-KR 로 디코딩해야 한글이 깨지지 않습니다 (`NAVER_API.md` 참고).
