import { useEffect } from 'react';

function App() {
  useEffect(() => {
    // Flutter 앱(public/index.html)으로 리디렉션
    // public 폴더의 파일은 루트 경로(/)로 서빙되므로, 파일명이 겹치지 않게 주의해야 합니다.
    // Flutter 빌드 결과물의 index.html이 public/index.html로 복사되었다면,
    // 현재 React 앱의 index.html과 충돌할 수 있습니다.
    // 따라서 Flutter 앱을 public/flutter/ 폴더에 넣고 이동하거나,
    // 아예 React 앱의 index.html을 Flutter 앱의 것으로 교체하는 것이 좋습니다.

    // 현재 구조상 public/index.html (Flutter)이 존재하므로,
    // 이를 서빙하기 위해 window.location.href를 변경합니다.
    // 단, Vite 개발 서버에서는 public/index.html이 루트로 서빙될 수 있습니다.

    // 여기서는 간단히 window.location.href를 사용하여 이동합니다.
    // 만약 Flutter 앱이 루트에 있다면 이미 보이고 있어야 하지만,
    // React 앱이 마운트되었다면 덮어스여졌을 수 있습니다.

    // 가장 확실한 방법은 React 앱 자체를 Flutter 앱을 보여주는 컨테이너로 쓰거나
    // 빌드 시점에 index.html을 교체하는 것입니다.

    // 우선 public/index.html이 복사되었다면, 빌드 시 루트의 index.html이 
    // React 앱의 진입점이 됩니다.

    // 차라리 iframe으로 띄우겠습니다.
  }, []);

  return (
    <div style={{ width: '100vw', height: '100vh', overflow: 'hidden' }}>
      <iframe
        src="./game.html"
        style={{ width: '100%', height: '100%', border: 'none' }}
        title="Sudoku Game"
      />
    </div>
  );
}

export default App;
