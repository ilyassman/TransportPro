# Script de test pour l'API des réservations
Write-Host "Test de l'API des réservations..." -ForegroundColor Green

# Test 1: Récupérer toutes les réservations disponibles
Write-Host "`n1. Test des réservations disponibles (sans camion assigné):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://192.168.1.104:8082/api/reservations/available" -Method GET
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Contenu: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Récupérer toutes les réservations en attente
Write-Host "`n2. Test des réservations en attente (avec ou sans camion):" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://192.168.1.104:8082/api/reservations/all/status/EN_ATTENTE" -Method GET
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Contenu: $($response.Content)" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nTest terminé!" -ForegroundColor Green 