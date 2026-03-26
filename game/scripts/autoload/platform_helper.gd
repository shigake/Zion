## PlatformHelper: detecta plataforma e retorna configuracoes especializadas
extends Node

## Retorna true se rodando em Android
func is_android() -> bool:
	return OS.get_name() == "Android"

## Retorna true se rodando em iOS
func is_ios() -> bool:
	return OS.get_name() == "iOS"

## Retorna true se rodando em plataforma mobile (Android ou iOS)
func is_mobile() -> bool:
	return is_android() or is_ios()

## Retorna true se rodando em desktop (Windows, Linux, macOS)
func is_desktop() -> bool:
	return OS.get_name() in ["Windows", "Linux", "macOS"]

## Retorna scale factor para UI (1.0 em desktop, 1.5 em mobile)
func get_ui_scale() -> float:
	if is_mobile():
		return 1.5
	return 1.0

## Retorna se multiplayer deve estar ativo
func is_multiplayer_enabled() -> bool:
	# Multiplayer desabilita em mobile (usa Steam Networking que não existe em Android/iOS)
	if is_mobile():
		return false
	return true
