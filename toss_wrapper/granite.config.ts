import { defineConfig } from "@apps-in-toss/web-framework/config";

export default defineConfig({
    appName: "sudokimeki", // 앱인토스 콘솔에서 설정한 앱 이름
    brand: {
        displayName: "스도키메키",
        primaryColor: "#3182F6",
        icon: "", // 아이콘이 아직 없으면 빈 문자열
        bridgeColorMode: "basic",
    },
    web: {
        host: "localhost",
        port: 5173,
        commands: {
            dev: "vite --host",
            build: "vite build",
        },
    },
    permissions: [],
    // Vite의 빌드 결과물 경로가 dist가 아닌 경우 설정 필요.
    // 기본적으로 Vite는 dist에 빌드하므로 outDir를 명시하지 않아도 되지만,
    // SDK가 dist를 바라보는지 확인 필요. 매뉴얼상 outdir 기본값이 dist임.
});
