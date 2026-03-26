extends Node

## Fabrica de modelos procedurais. Gera personagens e inimigos
## combinando primitivas 3D com silhuetas distintas.
## Substitui as primitivas simples por composicoes reconheciveis.

# ===================== PLAYER MODELS =====================

func create_ronin_model() -> Node3D:
	## Ronin: corpo esbelto + cabeca + hakama (saia) + katana nas costas
	var root = Node3D.new()

	# Corpo
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.22
	body.mesh.height = 0.7
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)

	# Hakama (saia samurai) - cone invertido
	var hakama = _mesh(CylinderMesh.new(), Vector3(0, 0.15, 0))
	hakama.mesh.top_radius = 0.22
	hakama.mesh.bottom_radius = 0.35
	hakama.mesh.height = 0.35
	root.add_child(hakama)

	# Katana nas costas
	var katana = _mesh(BoxMesh.new(), Vector3(-0.15, 0.7, -0.12))
	katana.mesh.size = Vector3(0.04, 0.55, 0.04)
	katana.rotation.z = deg_to_rad(15)
	root.add_child(katana)

	# Faixa na cabeca (headband)
	var band = _mesh(BoxMesh.new(), Vector3(0, 1.15, 0))
	band.mesh.size = Vector3(0.4, 0.04, 0.4)
	root.add_child(band)

	return root

func create_soldado_model() -> Node3D:
	## Soldado: corpo robusto + capacete + mochila + arma
	var root = Node3D.new()

	# Corpo robusto
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.55, 0))
	body.mesh.radius = 0.28
	body.mesh.height = 0.65
	root.add_child(body)

	# Cabeca com capacete
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.2
	head.mesh.height = 0.4
	root.add_child(head)

	# Capacete (achatado em cima)
	var helmet = _mesh(CylinderMesh.new(), Vector3(0, 1.18, 0))
	helmet.mesh.top_radius = 0.12
	helmet.mesh.bottom_radius = 0.22
	helmet.mesh.height = 0.12
	root.add_child(helmet)

	# Mochila
	var backpack = _mesh(BoxMesh.new(), Vector3(0, 0.6, -0.2))
	backpack.mesh.size = Vector3(0.25, 0.3, 0.15)
	root.add_child(backpack)

	# Ombros largos
	var shoulder_l = _mesh(SphereMesh.new(), Vector3(0.3, 0.8, 0))
	shoulder_l.mesh.radius = 0.1
	shoulder_l.mesh.height = 0.2
	root.add_child(shoulder_l)

	var shoulder_r = _mesh(SphereMesh.new(), Vector3(-0.3, 0.8, 0))
	shoulder_r.mesh.radius = 0.1
	shoulder_r.mesh.height = 0.2
	root.add_child(shoulder_r)

	return root

func create_mago_model() -> Node3D:
	## Mago: corpo fino + robe longo + chapeu pontudo + orbe flutuante
	var root = Node3D.new()

	# Robe (cone longo)
	var robe = _mesh(CylinderMesh.new(), Vector3(0, 0.35, 0))
	robe.mesh.top_radius = 0.18
	robe.mesh.bottom_radius = 0.4
	robe.mesh.height = 0.7
	root.add_child(robe)

	# Corpo superior
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.75, 0))
	body.mesh.radius = 0.18
	body.mesh.height = 0.4
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.16
	head.mesh.height = 0.32
	root.add_child(head)

	# Chapeu pontudo (cone)
	var hat = _mesh(CylinderMesh.new(), Vector3(0, 1.35, 0))
	hat.mesh.top_radius = 0.0
	hat.mesh.bottom_radius = 0.22
	hat.mesh.height = 0.4
	root.add_child(hat)

	# Aba do chapeu
	var brim = _mesh(CylinderMesh.new(), Vector3(0, 1.15, 0))
	brim.mesh.top_radius = 0.3
	brim.mesh.bottom_radius = 0.3
	brim.mesh.height = 0.03
	root.add_child(brim)

	# Orbe flutuante
	var orb = _mesh(SphereMesh.new(), Vector3(0.35, 0.9, 0.15))
	orb.mesh.radius = 0.08
	orb.mesh.height = 0.16
	root.add_child(orb)

	return root

func create_berserker_model() -> Node3D:
	## Berserker: corpo massivo + sem cabeca visivel (capacete) + machado grande
	var root = Node3D.new()

	# Corpo massivo
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.55, 0))
	body.mesh.radius = 0.32
	body.mesh.height = 0.7
	root.add_child(body)

	# Cabeca pequena (capacete viking)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.2
	head.mesh.height = 0.4
	root.add_child(head)

	# Chifres do capacete
	var horn_l = _mesh(CylinderMesh.new(), Vector3(0.2, 1.2, 0))
	horn_l.mesh.top_radius = 0.0
	horn_l.mesh.bottom_radius = 0.04
	horn_l.mesh.height = 0.2
	horn_l.rotation.z = deg_to_rad(-30)
	root.add_child(horn_l)

	var horn_r = _mesh(CylinderMesh.new(), Vector3(-0.2, 1.2, 0))
	horn_r.mesh.top_radius = 0.0
	horn_r.mesh.bottom_radius = 0.04
	horn_r.mesh.height = 0.2
	horn_r.rotation.z = deg_to_rad(30)
	root.add_child(horn_r)

	# Cinto de peles
	var belt = _mesh(CylinderMesh.new(), Vector3(0, 0.25, 0))
	belt.mesh.top_radius = 0.3
	belt.mesh.bottom_radius = 0.28
	belt.mesh.height = 0.12
	root.add_child(belt)

	# Ombros enormes
	var shoulder_l = _mesh(SphereMesh.new(), Vector3(0.35, 0.85, 0))
	shoulder_l.mesh.radius = 0.14
	shoulder_l.mesh.height = 0.28
	root.add_child(shoulder_l)

	var shoulder_r = _mesh(SphereMesh.new(), Vector3(-0.35, 0.85, 0))
	shoulder_r.mesh.radius = 0.14
	shoulder_r.mesh.height = 0.28
	root.add_child(shoulder_r)

	return root

func create_ninja_model() -> Node3D:
	## Ninja: corpo magro + mascara + cachecol esvoaçante
	var root = Node3D.new()

	# Corpo magro
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.55, 0))
	body.mesh.radius = 0.18
	body.mesh.height = 0.65
	root.add_child(body)

	# Cabeca com mascara
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.0, 0))
	head.mesh.radius = 0.16
	head.mesh.height = 0.32
	root.add_child(head)

	# Cachecol (retangulo atras)
	var scarf = _mesh(BoxMesh.new(), Vector3(0, 0.95, -0.2))
	scarf.mesh.size = Vector3(0.12, 0.08, 0.35)
	root.add_child(scarf)

	# Pernas visiveis (mais fino embaixo)
	var leg_l = _mesh(CylinderMesh.new(), Vector3(0.1, 0.12, 0))
	leg_l.mesh.top_radius = 0.08
	leg_l.mesh.bottom_radius = 0.06
	leg_l.mesh.height = 0.25
	root.add_child(leg_l)

	var leg_r = _mesh(CylinderMesh.new(), Vector3(-0.1, 0.12, 0))
	leg_r.mesh.top_radius = 0.08
	leg_r.mesh.bottom_radius = 0.06
	leg_r.mesh.height = 0.25
	root.add_child(leg_r)

	# Shuriken nas costas
	var star = _mesh(CylinderMesh.new(), Vector3(0.15, 0.7, -0.15))
	star.mesh.top_radius = 0.1
	star.mesh.bottom_radius = 0.1
	star.mesh.height = 0.02
	root.add_child(star)

	return root

func _create_necro_model() -> Node3D:
	## Necro: corpo encapuzado + manto longo + orbe flutuante
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.22
	body.mesh.height = 0.75
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)
	# Capuz pontudo
	var hood = _mesh(CylinderMesh.new(), Vector3(0, 1.3, -0.05))
	hood.mesh.top_radius = 0.02
	hood.mesh.bottom_radius = 0.2
	hood.mesh.height = 0.3
	root.add_child(hood)
	# Manto longo
	var cloak = _mesh(CylinderMesh.new(), Vector3(0, 0.2, 0))
	cloak.mesh.top_radius = 0.22
	cloak.mesh.bottom_radius = 0.35
	cloak.mesh.height = 0.5
	root.add_child(cloak)
	# Orbe flutuante
	var orb = _mesh(SphereMesh.new(), Vector3(0.3, 1.0, 0.15))
	orb.mesh.radius = 0.08
	orb.mesh.height = 0.16
	orb.set_meta("accent", true)
	root.add_child(orb)
	return root

func _create_pirata_model() -> Node3D:
	## Pirata: corpo robusto + chapeu tricorne + gancho
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.24
	body.mesh.height = 0.7
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)
	# Chapeu tricorne
	var hat_brim = _mesh(CylinderMesh.new(), Vector3(0, 1.3, 0))
	hat_brim.mesh.top_radius = 0.28
	hat_brim.mesh.bottom_radius = 0.28
	hat_brim.mesh.height = 0.04
	root.add_child(hat_brim)
	var hat_top = _mesh(CylinderMesh.new(), Vector3(0, 1.4, 0))
	hat_top.mesh.top_radius = 0.12
	hat_top.mesh.bottom_radius = 0.18
	hat_top.mesh.height = 0.15
	root.add_child(hat_top)
	# Gancho na mao
	var hook = _mesh(CylinderMesh.new(), Vector3(-0.3, 0.6, 0.1))
	hook.mesh.top_radius = 0.02
	hook.mesh.bottom_radius = 0.01
	hook.mesh.height = 0.15
	hook.set_meta("accent", true)
	root.add_child(hook)
	return root

func _create_engenheiro_model() -> Node3D:
	## Engenheiro: corpo com colete + capacete + drone nas costas
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.22
	body.mesh.height = 0.7
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.17
	head.mesh.height = 0.34
	root.add_child(head)
	# Capacete/goggle
	var helmet = _mesh(CylinderMesh.new(), Vector3(0, 1.2, 0))
	helmet.mesh.top_radius = 0.14
	helmet.mesh.bottom_radius = 0.18
	helmet.mesh.height = 0.12
	root.add_child(helmet)
	# Mochila
	var pack = _mesh(BoxMesh.new(), Vector3(0, 0.65, -0.2))
	pack.mesh.size = Vector3(0.25, 0.3, 0.15)
	root.add_child(pack)
	# Drone flutuante
	var drone = _mesh(BoxMesh.new(), Vector3(0.25, 1.4, 0))
	drone.mesh.size = Vector3(0.15, 0.06, 0.15)
	drone.set_meta("accent", true)
	root.add_child(drone)
	return root

func _create_vampiro_model() -> Node3D:
	## Vampiro: corpo elegante + capa + gola alta
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.2
	body.mesh.height = 0.75
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.15, 0))
	head.mesh.radius = 0.17
	head.mesh.height = 0.34
	root.add_child(head)
	# Gola alta da capa
	var collar = _mesh(CylinderMesh.new(), Vector3(0, 1.0, -0.08))
	collar.mesh.top_radius = 0.22
	collar.mesh.bottom_radius = 0.18
	collar.mesh.height = 0.15
	root.add_child(collar)
	# Capa longa
	var cape = _mesh(BoxMesh.new(), Vector3(0, 0.5, -0.18))
	cape.mesh.size = Vector3(0.5, 0.8, 0.06)
	root.add_child(cape)
	# Olhos vermelhos
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.07, 1.18, 0.14))
	eye_l.mesh.radius = 0.03
	eye_l.mesh.height = 0.06
	eye_l.set_meta("accent", true)
	root.add_child(eye_l)
	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.07, 1.18, 0.14))
	eye_r.mesh.radius = 0.03
	eye_r.mesh.height = 0.06
	eye_r.set_meta("accent", true)
	root.add_child(eye_r)
	return root

func _create_gladiador_model() -> Node3D:
	## Gladiador: corpo musculoso + elmo + escudo + lanca
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.28
	body.mesh.height = 0.7
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.19
	head.mesh.height = 0.38
	root.add_child(head)
	# Elmo com crista
	var helm = _mesh(CylinderMesh.new(), Vector3(0, 1.25, 0))
	helm.mesh.top_radius = 0.1
	helm.mesh.bottom_radius = 0.2
	helm.mesh.height = 0.15
	root.add_child(helm)
	var crest = _mesh(BoxMesh.new(), Vector3(0, 1.35, 0))
	crest.mesh.size = Vector3(0.04, 0.15, 0.25)
	root.add_child(crest)
	# Escudo
	var shield = _mesh(CylinderMesh.new(), Vector3(-0.35, 0.6, 0.1))
	shield.mesh.top_radius = 0.2
	shield.mesh.bottom_radius = 0.2
	shield.mesh.height = 0.04
	root.add_child(shield)
	# Ombreira
	var pauldron = _mesh(SphereMesh.new(), Vector3(0.28, 0.9, 0))
	pauldron.mesh.radius = 0.1
	pauldron.mesh.height = 0.15
	root.add_child(pauldron)
	return root

func _create_chef_model() -> Node3D:
	## Chef: corpo roliço + chapeu de chef + avental
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.55, 0))
	body.mesh.radius = 0.26
	body.mesh.height = 0.65
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)
	# Chapeu de chef (toque)
	var hat = _mesh(CylinderMesh.new(), Vector3(0, 1.35, 0))
	hat.mesh.top_radius = 0.16
	hat.mesh.bottom_radius = 0.14
	hat.mesh.height = 0.3
	root.add_child(hat)
	# Avental
	var apron = _mesh(BoxMesh.new(), Vector3(0, 0.45, 0.15))
	apron.mesh.size = Vector3(0.35, 0.45, 0.04)
	root.add_child(apron)
	# Frigideira
	var pan = _mesh(CylinderMesh.new(), Vector3(0.3, 0.7, 0.1))
	pan.mesh.top_radius = 0.12
	pan.mesh.bottom_radius = 0.12
	pan.mesh.height = 0.03
	pan.set_meta("accent", true)
	root.add_child(pan)
	return root

func _create_mystery_model() -> Node3D:
	## Mystery: silhueta obscura + ponto de interrogacao
	var root = Node3D.new()
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.22
	body.mesh.height = 0.7
	root.add_child(body)
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.1, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)
	# Manto misterioso
	var cloak = _mesh(CylinderMesh.new(), Vector3(0, 0.4, 0))
	cloak.mesh.top_radius = 0.22
	cloak.mesh.bottom_radius = 0.32
	cloak.mesh.height = 0.8
	root.add_child(cloak)
	# Capuz
	var hood = _mesh(CylinderMesh.new(), Vector3(0, 1.25, -0.03))
	hood.mesh.top_radius = 0.05
	hood.mesh.bottom_radius = 0.2
	hood.mesh.height = 0.2
	root.add_child(hood)
	return root

# ===================== ENEMY MODELS =====================

func create_slime_model() -> Node3D:
	## Slime: esfera achatada + olhos
	var root = Node3D.new()

	# Corpo achatado
	var body = _mesh(SphereMesh.new(), Vector3(0, 0.2, 0))
	body.mesh.radius = 0.35
	body.mesh.height = 0.45
	body.scale = Vector3(1.0, 0.7, 1.0)
	root.add_child(body)

	# Olho esquerdo
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.1, 0.3, 0.2))
	eye_l.mesh.radius = 0.06
	eye_l.mesh.height = 0.12
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	# Olho direito
	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.1, 0.3, 0.2))
	eye_r.mesh.radius = 0.06
	eye_r.mesh.height = 0.12
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	return root

func create_bat_model() -> Node3D:
	## Bat: corpo pequeno + asas triangulares
	var root = Node3D.new()

	# Corpo
	var body = _mesh(SphereMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.radius = 0.15
	body.mesh.height = 0.25
	root.add_child(body)

	# Asa esquerda (box achatado angulado)
	var wing_l = _mesh(BoxMesh.new(), Vector3(0.3, 0.65, 0))
	wing_l.mesh.size = Vector3(0.35, 0.02, 0.2)
	wing_l.rotation.z = deg_to_rad(15)
	root.add_child(wing_l)

	# Asa direita
	var wing_r = _mesh(BoxMesh.new(), Vector3(-0.3, 0.65, 0))
	wing_r.mesh.size = Vector3(0.35, 0.02, 0.2)
	wing_r.rotation.z = deg_to_rad(-15)
	root.add_child(wing_r)

	# Orelhas
	var ear_l = _mesh(CylinderMesh.new(), Vector3(0.08, 0.78, 0))
	ear_l.mesh.top_radius = 0.0
	ear_l.mesh.bottom_radius = 0.04
	ear_l.mesh.height = 0.12
	root.add_child(ear_l)

	var ear_r = _mesh(CylinderMesh.new(), Vector3(-0.08, 0.78, 0))
	ear_r.mesh.top_radius = 0.0
	ear_r.mesh.bottom_radius = 0.04
	ear_r.mesh.height = 0.12
	root.add_child(ear_r)

	return root

func create_skeleton_model() -> Node3D:
	## Skeleton: corpo fino + cranio + costelas visiveis
	var root = Node3D.new()

	# Corpo fino (espinha)
	var spine = _mesh(CylinderMesh.new(), Vector3(0, 0.45, 0))
	spine.mesh.top_radius = 0.06
	spine.mesh.bottom_radius = 0.06
	spine.mesh.height = 0.5
	root.add_child(spine)

	# Cranio
	var skull = _mesh(SphereMesh.new(), Vector3(0, 0.85, 0))
	skull.mesh.radius = 0.15
	skull.mesh.height = 0.28
	root.add_child(skull)

	# Mandibula
	var jaw = _mesh(BoxMesh.new(), Vector3(0, 0.72, 0.08))
	jaw.mesh.size = Vector3(0.15, 0.06, 0.1)
	root.add_child(jaw)

	# Costelas (3 pares)
	for i in range(3):
		var y = 0.55 - i * 0.1
		var rib_l = _mesh(BoxMesh.new(), Vector3(0.1, y, 0))
		rib_l.mesh.size = Vector3(0.15, 0.025, 0.06)
		rib_l.rotation.z = deg_to_rad(-10)
		root.add_child(rib_l)

		var rib_r = _mesh(BoxMesh.new(), Vector3(-0.1, y, 0))
		rib_r.mesh.size = Vector3(0.15, 0.025, 0.06)
		rib_r.rotation.z = deg_to_rad(10)
		root.add_child(rib_r)

	# Pelvis
	var pelvis = _mesh(BoxMesh.new(), Vector3(0, 0.2, 0))
	pelvis.mesh.size = Vector3(0.25, 0.06, 0.1)
	root.add_child(pelvis)

	return root

func create_zombie_model() -> Node3D:
	## Zombie runner: corpo curvado + bracos estendidos
	var root = Node3D.new()

	# Corpo curvado pra frente
	var body = _mesh(CapsuleMesh.new(), Vector3(0, 0.5, 0.05))
	body.mesh.radius = 0.22
	body.mesh.height = 0.6
	body.rotation.x = deg_to_rad(10)  # Inclinado pra frente
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 0.95, 0.1))
	head.mesh.radius = 0.16
	head.mesh.height = 0.32
	root.add_child(head)

	# Bracos estendidos pra frente
	var arm_l = _mesh(CylinderMesh.new(), Vector3(0.2, 0.65, 0.3))
	arm_l.mesh.top_radius = 0.05
	arm_l.mesh.bottom_radius = 0.04
	arm_l.mesh.height = 0.4
	arm_l.rotation.x = deg_to_rad(75)
	root.add_child(arm_l)

	var arm_r = _mesh(CylinderMesh.new(), Vector3(-0.2, 0.7, 0.25))
	arm_r.mesh.top_radius = 0.05
	arm_r.mesh.bottom_radius = 0.04
	arm_r.mesh.height = 0.35
	arm_r.rotation.x = deg_to_rad(65)
	root.add_child(arm_r)

	return root

func create_ghost_model() -> Node3D:
	## Ghost: forma eterea flutuante + cauda ondulada
	var root = Node3D.new()

	# Corpo principal (cone invertido suave)
	var body = _mesh(CylinderMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.top_radius = 0.2
	body.mesh.bottom_radius = 0.05
	body.mesh.height = 0.6
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.0, 0))
	head.mesh.radius = 0.22
	head.mesh.height = 0.4
	root.add_child(head)

	# Olhos brilhantes (marcados como accent para glow)
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.08, 1.0, 0.15))
	eye_l.mesh.radius = 0.04
	eye_l.mesh.height = 0.08
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.08, 1.0, 0.15))
	eye_r.mesh.radius = 0.04
	eye_r.mesh.height = 0.08
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	return root

func create_ghost_white_model() -> Node3D:
	## Fantasminha Branco: corpo etéreo brilhante, olhos grandes
	var root = Node3D.new()

	# Corpo (cone invertido suave)
	var body = _mesh(CylinderMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.top_radius = 0.22
	body.mesh.bottom_radius = 0.06
	body.mesh.height = 0.65
	root.add_child(body)

	# Cabeca arredondada
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.24
	head.mesh.height = 0.44
	root.add_child(head)

	# Olhos grandes brilhantes
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.09, 1.05, 0.17))
	eye_l.mesh.radius = 0.05
	eye_l.mesh.height = 0.1
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.09, 1.05, 0.17))
	eye_r.mesh.radius = 0.05
	eye_r.mesh.height = 0.1
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	# Boca oval (accent para brilho)
	var mouth = _mesh(SphereMesh.new(), Vector3(0, 0.93, 0.18))
	mouth.mesh.radius = 0.04
	mouth.mesh.height = 0.06
	root.add_child(mouth)
	_mark_as_accent(mouth)

	return root

func create_ghost_green_model() -> Node3D:
	## Fantasminha Verde: forma ondulada, olhos maliciosos
	var root = Node3D.new()

	# Corpo ondulado
	var body = _mesh(CylinderMesh.new(), Vector3(0, 0.55, 0))
	body.mesh.top_radius = 0.2
	body.mesh.bottom_radius = 0.08
	body.mesh.height = 0.6
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 0.98, 0))
	head.mesh.radius = 0.22
	head.mesh.height = 0.4
	root.add_child(head)

	# Olhos finos (maliciosos)
	var eye_l = _mesh(BoxMesh.new(), Vector3(0.08, 1.0, 0.16))
	eye_l.mesh.size = Vector3(0.08, 0.03, 0.04)
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(BoxMesh.new(), Vector3(-0.08, 1.0, 0.16))
	eye_r.mesh.size = Vector3(0.08, 0.03, 0.04)
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	# Cauda ondulada extra
	var tail = _mesh(CylinderMesh.new(), Vector3(0, 0.2, 0))
	tail.mesh.top_radius = 0.08
	tail.mesh.bottom_radius = 0.0
	tail.mesh.height = 0.25
	root.add_child(tail)

	return root

func create_ghost_blue_model() -> Node3D:
	## Fantasminha Azul: forma robusta, olhos tristes
	var root = Node3D.new()

	# Corpo mais largo
	var body = _mesh(CylinderMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.top_radius = 0.25
	body.mesh.bottom_radius = 0.1
	body.mesh.height = 0.65
	root.add_child(body)

	# Cabeca grande
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.25
	head.mesh.height = 0.46
	root.add_child(head)

	# Olhos grandes tristes (posicionados mais embaixo)
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.1, 1.0, 0.18))
	eye_l.mesh.radius = 0.05
	eye_l.mesh.height = 0.1
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.1, 1.0, 0.18))
	eye_r.mesh.radius = 0.05
	eye_r.mesh.height = 0.1
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	# Bracinhos curtos
	var arm_l = _mesh(CylinderMesh.new(), Vector3(0.22, 0.75, 0.05))
	arm_l.mesh.top_radius = 0.03
	arm_l.mesh.bottom_radius = 0.04
	arm_l.mesh.height = 0.2
	arm_l.rotation.z = deg_to_rad(-30)
	root.add_child(arm_l)

	var arm_r = _mesh(CylinderMesh.new(), Vector3(-0.22, 0.75, 0.05))
	arm_r.mesh.top_radius = 0.03
	arm_r.mesh.bottom_radius = 0.04
	arm_r.mesh.height = 0.2
	arm_r.rotation.z = deg_to_rad(30)
	root.add_child(arm_r)

	return root

func create_ghost_red_model() -> Node3D:
	## Fantasminha Vermelho: mais agressivo, estrela amarela no peito
	var root = Node3D.new()

	# Corpo (cone invertido)
	var body = _mesh(CylinderMesh.new(), Vector3(0, 0.6, 0))
	body.mesh.top_radius = 0.23
	body.mesh.bottom_radius = 0.07
	body.mesh.height = 0.7
	root.add_child(body)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.08, 0))
	head.mesh.radius = 0.23
	head.mesh.height = 0.42
	root.add_child(head)

	# Olhos raivosos (accent para glow)
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.09, 1.08, 0.16))
	eye_l.mesh.radius = 0.045
	eye_l.mesh.height = 0.09
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.09, 1.08, 0.16))
	eye_r.mesh.radius = 0.045
	eye_r.mesh.height = 0.09
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	# Sobrancelhas inclinadas (raivosas)
	var brow_l = _mesh(BoxMesh.new(), Vector3(0.09, 1.14, 0.17))
	brow_l.mesh.size = Vector3(0.08, 0.02, 0.02)
	brow_l.rotation.z = deg_to_rad(15)
	root.add_child(brow_l)

	var brow_r = _mesh(BoxMesh.new(), Vector3(-0.09, 1.14, 0.17))
	brow_r.mesh.size = Vector3(0.08, 0.02, 0.02)
	brow_r.rotation.z = deg_to_rad(-15)
	root.add_child(brow_r)

	# ★ ESTRELA AMARELA no peito — feita com 2 triangulos (prismas finos cruzados)
	# Triangulo 1 (apontando pra cima) — prisma achatado
	var star_up = _mesh(CylinderMesh.new(), Vector3(0, 0.78, 0.18))
	star_up.mesh.top_radius = 0.0
	star_up.mesh.bottom_radius = 0.1
	star_up.mesh.height = 0.12
	star_up.mesh.radial_segments = 3
	root.add_child(star_up)
	star_up.set_meta("star", true)

	# Triangulo 2 (apontando pra baixo) — prisma invertido
	var star_down = _mesh(CylinderMesh.new(), Vector3(0, 0.78, 0.18))
	star_down.mesh.top_radius = 0.1
	star_down.mesh.bottom_radius = 0.0
	star_down.mesh.height = 0.12
	star_down.mesh.radial_segments = 3
	root.add_child(star_down)
	star_down.set_meta("star", true)

	return root

func create_boss_model() -> Node3D:
	## Boss Necromancer: corpo grande + capa + coroa + orbe de poder
	var root = Node3D.new()

	# Robe grande
	var robe = _mesh(CylinderMesh.new(), Vector3(0, 0.5, 0))
	robe.mesh.top_radius = 0.35
	robe.mesh.bottom_radius = 0.6
	robe.mesh.height = 1.0
	root.add_child(robe)

	# Corpo superior
	var torso = _mesh(CapsuleMesh.new(), Vector3(0, 1.1, 0))
	torso.mesh.radius = 0.3
	torso.mesh.height = 0.5
	root.add_child(torso)

	# Cabeca
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.55, 0))
	head.mesh.radius = 0.22
	head.mesh.height = 0.44
	root.add_child(head)

	# Coroa de espinhos
	for i in range(5):
		var angle = (float(i) / 5.0) * TAU
		var spike = _mesh(CylinderMesh.new(), Vector3(cos(angle) * 0.18, 1.75, sin(angle) * 0.18))
		spike.mesh.top_radius = 0.0
		spike.mesh.bottom_radius = 0.03
		spike.mesh.height = 0.15
		root.add_child(spike)

	# Ombros com spikes
	var shoulder_l = _mesh(CylinderMesh.new(), Vector3(0.4, 1.25, 0))
	shoulder_l.mesh.top_radius = 0.0
	shoulder_l.mesh.bottom_radius = 0.12
	shoulder_l.mesh.height = 0.2
	root.add_child(shoulder_l)

	var shoulder_r = _mesh(CylinderMesh.new(), Vector3(-0.4, 1.25, 0))
	shoulder_r.mesh.top_radius = 0.0
	shoulder_r.mesh.bottom_radius = 0.12
	shoulder_r.mesh.height = 0.2
	root.add_child(shoulder_r)

	# Orbe de poder flutuante
	var orb = _mesh(SphereMesh.new(), Vector3(0, 1.9, 0.2))
	orb.mesh.radius = 0.12
	orb.mesh.height = 0.24
	root.add_child(orb)
	_mark_as_accent(orb)

	return root

func create_tank_model() -> Node3D:
	## Tank: corpo enorme quadrado + escudo
	var root = Node3D.new()

	# Corpo massivo
	var body = _mesh(BoxMesh.new(), Vector3(0, 0.5, 0))
	body.mesh.size = Vector3(0.9, 0.8, 0.7)
	root.add_child(body)

	# Cabeca pequena
	var head = _mesh(SphereMesh.new(), Vector3(0, 1.05, 0))
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)

	# Escudo na frente
	var shield = _mesh(BoxMesh.new(), Vector3(0, 0.5, 0.4))
	shield.mesh.size = Vector3(0.7, 0.6, 0.06)
	root.add_child(shield)

	return root

func create_bomber_model() -> Node3D:
	## Bomber: corpo redondo como bomba + pavio em cima
	var root = Node3D.new()

	# Corpo esférico (bomba)
	var body = _mesh(SphereMesh.new(), Vector3(0, 0.3, 0))
	body.mesh.radius = 0.28
	body.mesh.height = 0.56
	root.add_child(body)

	# Pavio
	var fuse = _mesh(CylinderMesh.new(), Vector3(0, 0.6, 0))
	fuse.mesh.top_radius = 0.02
	fuse.mesh.bottom_radius = 0.03
	fuse.mesh.height = 0.2
	root.add_child(fuse)

	# Faísca no topo (accent para glow)
	var spark = _mesh(SphereMesh.new(), Vector3(0, 0.72, 0))
	spark.mesh.radius = 0.04
	spark.mesh.height = 0.08
	root.add_child(spark)
	_mark_as_accent(spark)

	# Olhos
	var eye_l = _mesh(SphereMesh.new(), Vector3(0.1, 0.35, 0.22))
	eye_l.mesh.radius = 0.05
	eye_l.mesh.height = 0.1
	root.add_child(eye_l)
	_mark_as_accent(eye_l)

	var eye_r = _mesh(SphereMesh.new(), Vector3(-0.1, 0.35, 0.22))
	eye_r.mesh.radius = 0.05
	eye_r.mesh.height = 0.1
	root.add_child(eye_r)
	_mark_as_accent(eye_r)

	return root

func create_swarm_model() -> Node3D:
	## Swarm: cluster of 5 tiny spheres arranged in a group, insect-like
	var root = Node3D.new()

	var offsets = [
		Vector3(0, 0.3, 0),
		Vector3(0.12, 0.35, 0.05),
		Vector3(-0.1, 0.28, -0.05),
		Vector3(0.05, 0.4, -0.08),
		Vector3(-0.07, 0.22, 0.07),
	]

	for offset in offsets:
		var bug = _mesh(SphereMesh.new(), offset)
		bug.mesh.radius = 0.1
		bug.mesh.height = 0.2
		root.add_child(bug)

	return root

func create_mimic_model() -> Node3D:
	## Mimic: chest-like shape (box body + slightly open lid on top)
	var root = Node3D.new()

	# Chest body
	var body = _mesh(BoxMesh.new(), Vector3(0, 0.2, 0))
	body.mesh.size = Vector3(0.5, 0.35, 0.35)
	root.add_child(body)

	# Lid (slightly open, rotated back)
	var lid = _mesh(BoxMesh.new(), Vector3(0, 0.42, -0.08))
	lid.mesh.size = Vector3(0.52, 0.08, 0.37)
	lid.rotation.x = deg_to_rad(-20)
	root.add_child(lid)

	# Teeth (accent glow for menacing look)
	var tooth_l = _mesh(CylinderMesh.new(), Vector3(0.12, 0.38, 0.15))
	tooth_l.mesh.top_radius = 0.0
	tooth_l.mesh.bottom_radius = 0.03
	tooth_l.mesh.height = 0.1
	root.add_child(tooth_l)
	_mark_as_accent(tooth_l)

	var tooth_r = _mesh(CylinderMesh.new(), Vector3(-0.12, 0.38, 0.15))
	tooth_r.mesh.top_radius = 0.0
	tooth_r.mesh.bottom_radius = 0.03
	tooth_r.mesh.height = 0.1
	root.add_child(tooth_r)
	_mark_as_accent(tooth_r)

	# Eye peering from inside
	var eye = _mesh(SphereMesh.new(), Vector3(0, 0.32, 0.12))
	eye.mesh.radius = 0.06
	eye.mesh.height = 0.12
	root.add_child(eye)
	_mark_as_accent(eye)

	return root

# ===================== GLB LOADER =====================

const KENNEY_NATURE := "res://assets/models/downloaded/kenney/nature-kit/Models/GLTF format/"
const KENNEY_DUNGEON := "res://assets/models/downloaded/kenney/mini-dungeon/Models/GLB format/"
const KAYKIT_GAME := "res://assets/models/downloaded/kaykit/mini-game-variety/Models/gltf/"

## Escala dos modelos KayKit/Kenney para caber no jogo
const CHARACTER_SCALE := Vector3(1.2, 1.2, 1.2)
const ENEMY_SCALE := Vector3(1.0, 1.0, 1.0)
const BOSS_SCALE := Vector3(2.0, 2.0, 2.0)

func _try_load_glb(path: String, model_scale := Vector3.ONE) -> Node3D:
	## Tenta carregar modelo .glb. Retorna null se nao encontrar.
	if not ResourceLoader.exists(path):
		return null
	var scene = load(path) as PackedScene
	if scene == null:
		return null
	var instance = scene.instantiate()
	if instance == null:
		return null
	# Wrap in Node3D root for compatibility with existing code
	var root = Node3D.new()
	root.set_meta("glb_model", true)
	instance.scale = model_scale
	root.add_child(instance)
	return root

func load_prop(file_name: String, source: String = "nature") -> Node3D:
	## Carrega um modelo de prop dos assets baixados.
	## source: "nature" (Kenney nature-kit), "dungeon" (Kenney mini-dungeon), "game" (KayKit)
	var base_path: String
	match source:
		"nature": base_path = KENNEY_NATURE
		"dungeon": base_path = KENNEY_DUNGEON
		"game": base_path = KAYKIT_GAME
		_: base_path = KENNEY_NATURE
	var path = base_path + file_name
	if not ResourceLoader.exists(path):
		return null
	var scene = load(path) as PackedScene
	if scene == null:
		return null
	var instance = scene.instantiate()
	return instance

func get_weapon_model(weapon_id: String) -> Node3D:
	## Carrega modelo 3D de uma arma
	var glb_path = "res://assets/models/weapons/%s.glb" % weapon_id
	return _try_load_glb(glb_path, Vector3(0.4, 0.4, 0.4))

func attach_weapon_model(mesh_node: MeshInstance3D, weapon_id: String, model_scale := Vector3(0.4, 0.4, 0.4)) -> void:
	## Carrega .glb de arma e acopla no MeshInstance3D, escondendo a primitiva
	var glb_path = "res://assets/models/weapons/%s.glb" % weapon_id
	var model = _try_load_glb(glb_path, model_scale)
	if model:
		mesh_node.add_child(model)
		mesh_node.mesh = null

# ===================== HELPERS =====================

func _mesh(mesh_res: Mesh, pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.position = pos
	return mi

func _mark_as_accent(mi: MeshInstance3D) -> void:
	## Marca mesh como "accent" — recebe material de glow em vez de cel-shader
	mi.set_meta("accent", true)

func apply_model_materials(root: Node3D, base_color: Color) -> void:
	## Aplica cel-shader a todos os meshes do modelo, glow nos accents.
	## Modelos .glb importados preservam seus materiais originais.
	if root.has_meta("glb_model"):
		return
	for child in root.get_children():
		if child is MeshInstance3D:
			if child.has_meta("star"):
				# Estrela amarela brilhante (para GhostRed)
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(1.0, 0.9, 0.1)
				mat.emission_enabled = true
				mat.emission = Color(1.0, 0.85, 0.0)
				mat.emission_energy_multiplier = 4.0
				child.material_override = mat
			elif child.has_meta("accent"):
				# Accent: olhos, orbes — glow branco/brilhante
				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color.WHITE
				mat.emission_enabled = true
				mat.emission = Color.WHITE
				mat.emission_energy_multiplier = 3.0
				child.material_override = mat
			else:
				VisualSetup.apply_cel_shader_to_mesh(child, base_color)

func get_model_for_character(char_id: String) -> Node3D:
	# Try loading .glb model first (KayKit Adventurers)
	var glb_path = "res://assets/models/characters/%s.glb" % char_id
	var loaded = _try_load_glb(glb_path, CHARACTER_SCALE)
	if loaded:
		return loaded
	# Fallback to procedural
	match char_id:
		"ronin": return create_ronin_model()
		"soldado": return create_soldado_model()
		"mago": return create_mago_model()
		"berserker": return create_berserker_model()
		"ninja": return create_ninja_model()
		"necro": return _create_necro_model()
		"pirata": return _create_pirata_model()
		"engenheiro": return _create_engenheiro_model()
		"vampiro": return _create_vampiro_model()
		"gladiador": return _create_gladiador_model()
		"chef": return _create_chef_model()
		"mystery": return _create_mystery_model()
	return create_ronin_model()

func _clean_enemy_name(raw_name: String) -> String:
	## Strip Godot's auto-rename suffixes (@N, trailing digits) from node names.
	## e.g. "@Slime@2" -> "Slime", "Skeleton3" -> "Skeleton"
	var clean = raw_name.replace("@", "")
	while clean.length() > 0 and clean[-1].is_valid_int():
		clean = clean.substr(0, clean.length() - 1)
	return clean

func get_model_for_enemy(enemy_name: String) -> Node3D:
	var clean_name = _clean_enemy_name(enemy_name)
	# Map enemy names to .glb file names
	var glb_map = {
		"Slime": "slime", "SlimeBig": "slime_big",
		"Bat": "bat", "Skeleton": "skeleton",
		"SkeletonArcher": "skeleton_archer",
		"ZombieRunner": "zombie", "Ghost": "ghost",
		"Tank": "tank", "Bomber": "bomber",
		"Swarm": "swarm", "Mimic": "mimic",
		"BossNecromancer": "boss_necromancer",
		"BossFairyQueen": "boss_fairy_queen",
		"BossAlienCow": "boss_alien_cow",
		"BossAIOverlord": "boss_ai_overlord",
		"BossDemonLord": "boss_demon_lord",
		"BossLeviathan": "boss_leviathan",
		"BossEmperor": "boss_emperor",
		"BossSingularity": "boss_singularity",
		"BossDracula": "boss_dracula",
		"BossSugarKing": "boss_sugar_king",
	}
	# Try .glb model
	var file_name = glb_map.get(clean_name, clean_name.to_snake_case())
	var folder = "bosses" if clean_name.begins_with("Boss") else "enemies"
	var s = BOSS_SCALE if clean_name.begins_with("Boss") else ENEMY_SCALE
	var glb_path = "res://assets/models/%s/%s.glb" % [folder, file_name]
	var loaded = _try_load_glb(glb_path, s)
	if loaded:
		return loaded
	# Fallback to procedural
	match clean_name:
		"Slime", "SlimeBig": return create_slime_model()
		"Bat": return create_bat_model()
		"Skeleton", "SkeletonArcher": return create_skeleton_model()
		"ZombieRunner": return create_zombie_model()
		"Ghost": return create_ghost_model()
		"GhostWhite": return create_ghost_white_model()
		"GhostGreen": return create_ghost_green_model()
		"GhostBlue": return create_ghost_blue_model()
		"GhostRed": return create_ghost_red_model()
		"Tank": return create_tank_model()
		"Bomber": return create_bomber_model()
		"BossNecromancer": return create_boss_model()
		"Swarm": return create_swarm_model()
		"Mimic": return create_mimic_model()
		"ToothFairy": return create_bat_model()
	return create_slime_model()

# ===================== PROP SCATTER SYSTEM =====================

## Catalogo de props por tema/bioma, mapeia para arquivos .glb reais
var _prop_catalog := {
	# Floresta
	"tree": ["tree_default.glb", "tree_oak.glb", "tree_fat.glb", "tree_tall.glb", "tree_simple.glb"],
	"tree_pine": ["tree_pineDefaultA.glb", "tree_pineDefaultB.glb", "tree_pineSmallA.glb"],
	"tree_dark": ["tree_default_dark.glb", "tree_thin_dark.glb", "tree_oak_dark.glb"],
	"tree_fall": ["tree_default_fall.glb", "tree_oak_fall.glb", "tree_thin_fall.glb"],
	"tree_palm": ["tree_palmDetailedShort.glb", "tree_palmDetailedTall.glb", "tree_palmShort.glb"],
	"rock_large": ["rock_largeA.glb", "rock_largeB.glb", "rock_largeC.glb", "rock_largeD.glb", "rock_largeE.glb", "rock_largeF.glb"],
	"rock_small": ["rock_smallA.glb", "rock_smallB.glb", "rock_smallC.glb", "rock_smallD.glb", "rock_smallE.glb"],
	"rock_tall": ["rock_tallA.glb", "rock_tallB.glb", "rock_tallC.glb", "rock_tallD.glb", "rock_tallE.glb"],
	"stone_large": ["stone_largeA.glb", "stone_largeB.glb", "stone_largeC.glb", "stone_largeD.glb", "stone_largeE.glb"],
	"stone_small": ["stone_smallA.glb", "stone_smallB.glb", "stone_smallC.glb", "stone_smallD.glb", "stone_smallE.glb"],
	"stone_tall": ["stone_tallA.glb", "stone_tallB.glb", "stone_tallC.glb", "stone_tallD.glb", "stone_tallE.glb"],
	"mushroom": ["mushroom_red.glb", "mushroom_tan.glb", "mushroom_redTall.glb", "mushroom_tanTall.glb"],
	"mushroom_group": ["mushroom_redGroup.glb", "mushroom_tanGroup.glb"],
	"grass": ["grass.glb", "grass_large.glb", "grass_leafs.glb", "grass_leafsLarge.glb"],
	"flower": ["flower_redA.glb", "flower_redB.glb", "flower_purpleA.glb", "flower_purpleB.glb", "flower_yellowA.glb", "flower_yellowB.glb"],
	"bush": ["plant_bush.glb", "plant_bushSmall.glb", "plant_bushLarge.glb"],
	"plant_flat": ["plant_flatShort.glb", "plant_flatTall.glb"],
	"log": ["log.glb", "log_large.glb", "log_stack.glb", "log_stackLarge.glb"],
	"stump": ["stump_round.glb", "stump_roundDetailed.glb", "stump_old.glb", "stump_oldTall.glb"],
	"fence": ["fence_simple.glb", "fence_planks.glb", "fence_bend.glb"],
	"crops": ["crops_cornStageA.glb", "crops_cornStageB.glb", "crops_wheatStageA.glb", "crops_wheatStageB.glb", "crops_leafsStageA.glb"],
	"cliff": ["cliff_block_rock.glb", "cliff_block_stone.glb", "cliff_corner_rock.glb"],
	"cactus": ["cactus_short.glb", "cactus_tall.glb"],
	"lily": ["lily_small.glb", "lily_large.glb"],
	"tent": ["tent_detailedOpen.glb", "tent_detailedClosed.glb"],
	"campfire": ["campfire_stones.glb", "campfire_logs.glb"],
	"statue": ["statue_obelisk.glb", "statue_column.glb", "statue_columnDamaged.glb"],
	"bridge": ["bridge_center_stoneRound.glb", "bridge_side_stoneRound.glb"],
	"sign": ["sign.glb"],
	"hanging_moss": ["hanging_moss.glb"],
	# Kenney mini-dungeon
	"dungeon_wall": ["wall.glb", "wall-half.glb", "wall-narrow.glb", "wall-opening.glb"],
	"dungeon_column": ["column.glb"],
	"dungeon_barrel": ["barrel.glb"],
	"dungeon_chest": ["chest.glb"],
	"dungeon_banner": ["banner.glb"],
	"dungeon_gate": ["gate.glb"],
	"dungeon_stairs": ["stairs.glb"],
	"dungeon_rocks": ["rocks.glb", "stones.glb"],
	"dungeon_trap": ["trap.glb"],
	"dungeon_floor": ["floor.glb", "floor-detail.glb"],
	"dungeon_wood": ["wood-structure.glb", "wood-support.glb"],
}

func scatter_nature_props(parent: Node3D, prop_type: String, count: int, area_size: float,
		scale_range := Vector2(0.8, 1.5), y_offset := 0.0, avoid_center := 5.0) -> void:
	## Espalha props do Kenney nature-kit numa area. Usa modelos reais.
	var variants: Array = _prop_catalog.get(prop_type, [])
	if variants.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		var file_name: String = variants[rng.randi() % variants.size()]
		var model = load_prop(file_name, "nature")
		if model == null:
			continue
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < avoid_center and abs(z) < avoid_center:
			x += avoid_center * 2.0 * sign(x) if x != 0.0 else avoid_center * 2.0
		model.position = Vector3(x, y_offset, z)
		model.rotation.y = rng.randf() * TAU
		var s = rng.randf_range(scale_range.x, scale_range.y)
		model.scale = Vector3(s, s, s)
		parent.add_child(model)

func scatter_dungeon_props(parent: Node3D, prop_type: String, count: int, area_size: float,
		scale_range := Vector2(0.8, 1.2), y_offset := 0.0, avoid_center := 5.0) -> void:
	## Espalha props do Kenney mini-dungeon numa area.
	var variants: Array = _prop_catalog.get(prop_type, [])
	if variants.is_empty():
		return
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		var file_name: String = variants[rng.randi() % variants.size()]
		var model = load_prop(file_name, "dungeon")
		if model == null:
			continue
		var x = rng.randf_range(-area_size, area_size)
		var z = rng.randf_range(-area_size, area_size)
		if abs(x) < avoid_center and abs(z) < avoid_center:
			x += avoid_center * 2.0 * sign(x) if x != 0.0 else avoid_center * 2.0
		model.position = Vector3(x, y_offset, z)
		model.rotation.y = rng.randf() * TAU
		var s = rng.randf_range(scale_range.x, scale_range.y)
		model.scale = Vector3(s, s, s)
		parent.add_child(model)
