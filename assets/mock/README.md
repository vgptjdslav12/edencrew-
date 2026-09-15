이 폴더에는 개발 중 사용할 Naver API 응답 샘플이 들어 있습니다.
네트워크 상태와 무관하게 파싱/UI 작업을 진행하기 위한 오프라인 자료입니다.

## 파일 구성

| 파일 | 원본 endpoint | 비고 |
| --- | --- | --- |
| `autocomplete_samsung.json` | `GET https://ac.stock.naver.com/ac?q=삼성&target=stock,ipo,index,marketindicator` | 여러 종목이 매칭되는 일반 케이스 |
| `autocomplete_kakao.json` | 같은 endpoint, `q=카카오` | 다른 검색어 케이스 |
| `autocomplete_empty.json` | 같은 endpoint, `q=zzzzzzzz` | `items` 가 비어 있는 케이스 |
| `realtime_quotes.json` | `GET https://polling.finance.naver.com/api/realtime?query=SERVICE_ITEM:005930,000660,035420,035720,207940,051910` | 관심종목 다건을 한 번에 조회한 응답 |
| `meta_{symbol}.json` | `GET https://stock.naver.com/api/securityFe/api/fchart/domestic/stock/{symbol}` | 6개 심볼(`005930`, `000660`, `035420`, `035720`, `207940`, `051910`) |
| `sise_day_005930_p1.html` … `_p3.html` | `GET https://finance.naver.com/item/sise_day.naver?code=005930&page={1..3}` | 페이지네이션이 필요한 일별 시세 HTML 3페이지 |
| `sise_day_000660_p1.html` | 같은 endpoint, `code=000660&page=1` | 다른 종목의 1페이지 |

## 인코딩 메모

- 자동완성(`ac.stock.naver.com`), 메타데이터(`stock.naver.com/api/...`) 응답은 **UTF-8** JSON.
- 실시간 시세(`polling.finance.naver.com`) 응답의 `Content-Type` 은 `text/plain;charset=EUC-KR`.
- 일별 시세(`finance.naver.com/item/sise_day.naver`) 응답은 **EUC-KR HTML**.
- 저장 시 EUC-KR(CP949) → UTF-8 로 다시 디코딩해 두었으므로, 앱에서 `rootBundle.loadString` 으로 바로 읽을 수 있습니다.
- 실제 API 를 호출할 때는 바이트 스트림을 EUC-KR 로 디코딩해야 한글이 깨지지 않습니다. (`NAVER_API.md` 의 주의사항)
