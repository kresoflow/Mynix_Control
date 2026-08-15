{{flutter_js}}
{{flutter_build_config}}

const splashScreen = document.getElementById('splash-screen');
const updateOverlay = document.getElementById('update-overlay');

// Initialize Flutter
_flutter.loader.load({
    onEntrypointLoaded: async function(engineInitializer) {
        const appRunner = await engineInitializer.initializeEngine();
        
        // Remove the splash screen smoothly
        if (splashScreen) {
            splashScreen.style.opacity = '0';
            setTimeout(() => {
                splashScreen.remove();
            }, 500);
        }

        await appRunner.runApp();
    }
});

// Setup Service Worker Update Listener
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function () {
        const swName = 'flutter_' + 'service_' + 'worker.js?v=' + {{flutter_service_worker_version}};
        navigator.serviceWorker.register(swName).then((reg) => {
            reg.addEventListener('updatefound', () => {
                const newWorker = reg.installing;
                if (newWorker) {
                    newWorker.addEventListener('statechange', () => {
                        // Check if it's an update (not the very first install)
                        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                            // New update available! Show notification
                            if (updateOverlay) {
                                updateOverlay.classList.add('visible');
                            }
                            
                            // Auto-reload after 2.5 seconds to apply update
                            setTimeout(() => {
                                window.location.reload(true);
                            }, 2500);
                        }
                    });
                }
            });
        });
    });
}
