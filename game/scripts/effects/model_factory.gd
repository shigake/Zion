extends Node

## Fabrica de modelos procedurais. Gera personagens e inimigos
## combinando primitivas 3D com silhuetas distintas.
## Substitui as primitivas simples por composicoes reconheciveis.

# ===================== PLAYER MODELS =====================

func create_ronin_model() -> Node3D:
	## Ronin: silhueta heroica anime/JRPG com hakama em camadas,
	## headband esvoacante e katana ornamentada.
	var root = Node3D.new()
	var outfit_color = Color(0.18, 0.48, 0.62)
	var cloth_shadow = Color(0.05, 0.14, 0.22)
	var cream_color = Color(0.84, 0.88, 0.79)
	var sash_color = Color(0.72, 0.22, 0.22)
	var gold_color = Color(0.84, 0.68, 0.25)
	var skin_color = Color(0.93, 0.81, 0.70)
	var hair_color = Color(0.08, 0.10, 0.15)
	var leather_color = Color(0.22, 0.13, 0.09)
	var spirit_color = Color(0.33, 0.88, 0.97)

	var body = _styled(_mesh(CapsuleMesh.new(), Vector3(0, 0.68, 0)), {
		"base_color": outfit_color,
		"shadow_color": cloth_shadow,
		"rim_color": Color(0.82, 0.95, 1.0, 0.65),
		"toon_steps": 4.0,
		"outline_width": 0.03,
	})
	body.mesh.radius = 0.21
	body.mesh.height = 0.78
	root.add_child(body)

	var chest_panel = _styled(_mesh(BoxMesh.new(), Vector3(0, 0.76, 0.13)), {
		"base_color": cream_color,
		"shadow_color": Color(0.30, 0.32, 0.30),
		"rim_color": Color(0.98, 0.96, 0.90, 0.30),
		"outline_width": 0.024,
	})
	chest_panel.mesh.size = Vector3(0.32, 0.30, 0.09)
	root.add_child(chest_panel)

	var collar = _styled(_mesh(BoxMesh.new(), Vector3(0, 0.94, 0.06)), {
		"base_color": cream_color,
		"shadow_color": Color(0.32, 0.34, 0.31),
		"outline_width": 0.020,
	})
	collar.mesh.size = Vector3(0.24, 0.08, 0.12)
	root.add_child(collar)

	var shoulder_guard = _styled(_mesh(BoxMesh.new(), Vector3(-0.26, 0.90, 0.02), Vector3(0, 0, deg_to_rad(16))), {
		"base_color": gold_color,
		"shadow_color": Color(0.36, 0.24, 0.06),
		"rim_color": Color(1.0, 0.92, 0.65, 0.35),
		"outline_width": 0.026,
	})
	shoulder_guard.mesh.size = Vector3(0.18, 0.11, 0.24)
	root.add_child(shoulder_guard)

	var sleeve_l = _styled(_mesh(CylinderMesh.new(), Vector3(0.25, 0.66, 0.02), Vector3(0, 0, deg_to_rad(-24))), {
		"base_color": outfit_color,
		"shadow_color": cloth_shadow,
		"outline_width": 0.024,
	})
	sleeve_l.mesh.top_radius = 0.07
	sleeve_l.mesh.bottom_radius = 0.06
	sleeve_l.mesh.height = 0.34
	root.add_child(sleeve_l)

	var sleeve_r = _styled(_mesh(CylinderMesh.new(), Vector3(-0.28, 0.66, 0.02), Vector3(0, 0, deg_to_rad(20))), {
		"base_color": outfit_color.darkened(0.08),
		"shadow_color": cloth_shadow.darkened(0.10),
		"outline_width": 0.024,
	})
	sleeve_r.mesh.top_radius = 0.07
	sleeve_r.mesh.bottom_radius = 0.06
	sleeve_r.mesh.height = 0.34
	root.add_child(sleeve_r)

	var bracer_l = _styled(_mesh(BoxMesh.new(), Vector3(0.33, 0.55, 0.08), Vector3(0, 0, deg_to_rad(-18))), {
		"base_color": leather_color,
		"shadow_color": Color(0.08, 0.05, 0.04),
		"outline_width": 0.022,
	})
	bracer_l.mesh.size = Vector3(0.09, 0.20, 0.10)
	root.add_child(bracer_l)

	var bracer_r = _styled(_mesh(BoxMesh.new(), Vector3(-0.34, 0.56, 0.08), Vector3(0, 0, deg_to_rad(14))), {
		"base_color": leather_color,
		"shadow_color": Color(0.08, 0.05, 0.04),
		"outline_width": 0.022,
	})
	bracer_r.mesh.size = Vector3(0.09, 0.20, 0.10)
	root.add_child(bracer_r)

	var sash = _styled(_mesh(CylinderMesh.new(), Vector3(0, 0.38, 0)), {
		"base_color": sash_color,
		"shadow_color": Color(0.18, 0.03, 0.03),
		"rim_color": Color(1.0, 0.72, 0.62, 0.25),
		"outline_width": 0.024,
	})
	sash.mesh.top_radius = 0.25
	sash.mesh.bottom_radius = 0.27
	sash.mesh.height = 0.12
	root.add_child(sash)

	var sash_knot = _styled(_mesh(BoxMesh.new(), Vector3(0.14, 0.38, 0.18), Vector3(0, 0, deg_to_rad(10))), {
		"base_color": sash_color.lightened(0.08),
		"shadow_color": Color(0.22, 0.04, 0.04),
		"outline_width": 0.022,
	})
	sash_knot.mesh.size = Vector3(0.12, 0.09, 0.10)
	root.add_child(sash_knot)

	var hakama = _styled(_mesh(CylinderMesh.new(), Vector3(0, 0.22, 0)), {
		"base_color": outfit_color.darkened(0.04),
		"shadow_color": cloth_shadow,
		"rim_color": Color(0.78, 0.91, 1.0, 0.38),
		"outline_width": 0.028,
	})
	hakama.mesh.top_radius = 0.24
	hakama.mesh.bottom_radius = 0.38
	hakama.mesh.height = 0.46
	root.add_child(hakama)

	var front_flap = _styled(_mesh(BoxMesh.new(), Vector3(0, 0.23, 0.18), Vector3(deg_to_rad(8), 0, 0)), {
		"base_color": cream_color,
		"shadow_color": Color(0.33, 0.34, 0.31),
		"outline_width": 0.022,
	})
	front_flap.mesh.size = Vector3(0.18, 0.40, 0.05)
	root.add_child(front_flap)

	var back_flap = _styled(_mesh(BoxMesh.new(), Vector3(0, 0.22, -0.16), Vector3(deg_to_rad(-6), 0, 0)), {
		"base_color": outfit_color.darkened(0.10),
		"shadow_color": cloth_shadow.darkened(0.10),
		"outline_width": 0.022,
	})
	back_flap.mesh.size = Vector3(0.22, 0.42, 0.06)
	root.add_child(back_flap)

	var side_flap_l = _styled(_mesh(BoxMesh.new(), Vector3(0.18, 0.20, 0.04), Vector3(0, 0, deg_to_rad(-10))), {
		"base_color": outfit_color.lightened(0.06),
		"shadow_color": cloth_shadow,
		"outline_width": 0.022,
	})
	side_flap_l.mesh.size = Vector3(0.10, 0.36, 0.08)
	root.add_child(side_flap_l)

	var side_flap_r = _styled(_mesh(BoxMesh.new(), Vector3(-0.18, 0.20, 0.04), Vector3(0, 0, deg_to_rad(10))), {
		"base_color": outfit_color.lightened(0.02),
		"shadow_color": cloth_shadow,
		"outline_width": 0.022,
	})
	side_flap_r.mesh.size = Vector3(0.10, 0.36, 0.08)
	root.add_child(side_flap_r)

	var boot_l = _styled(_mesh(CylinderMesh.new(), Vector3(0.12, 0.01, 0.02)), {
		"base_color": leather_color,
		"shadow_color": Color(0.08, 0.05, 0.04),
		"outline_width": 0.022,
	})
	boot_l.mesh.top_radius = 0.07
	boot_l.mesh.bottom_radius = 0.08
	boot_l.mesh.height = 0.22
	root.add_child(boot_l)

	var boot_r = _styled(_mesh(CylinderMesh.new(), Vector3(-0.12, 0.01, 0.02)), {
		"base_color": leather_color,
		"shadow_color": Color(0.08, 0.05, 0.04),
		"outline_width": 0.022,
	})
	boot_r.mesh.top_radius = 0.07
	boot_r.mesh.bottom_radius = 0.08
	boot_r.mesh.height = 0.22
	root.add_child(boot_r)

	var head = _styled(_mesh(SphereMesh.new(), Vector3(0, 1.12, 0.01)), {
		"base_color": skin_color,
		"shadow_color": Color(0.42, 0.28, 0.20),
		"rim_color": Color(1.0, 0.95, 0.80, 0.18),
		"outline_width": 0.022,
	})
	head.mesh.radius = 0.18
	head.mesh.height = 0.36
	root.add_child(head)

	var hair_back = _styled(_mesh(SphereMesh.new(), Vector3(0, 1.14, -0.05), Vector3.ZERO, Vector3(1.0, 1.0, 0.85)), {
		"base_color": hair_color,
		"shadow_color": Color(0.02, 0.03, 0.05),
		"rim_color": Color(0.28, 0.33, 0.42, 0.12),
		"outline_width": 0.022,
	})
	hair_back.mesh.radius = 0.19
	hair_back.mesh.height = 0.36
	root.add_child(hair_back)

	var bangs = _styled(_mesh(BoxMesh.new(), Vector3(0, 1.15, 0.15), Vector3(deg_to_rad(8), 0, 0)), {
		"base_color": hair_color,
		"shadow_color": Color(0.02, 0.03, 0.05),
		"outline_width": 0.018,
	})
	bangs.mesh.size = Vector3(0.26, 0.11, 0.07)
	root.add_child(bangs)

	var topknot = _styled(_mesh(CylinderMesh.new(), Vector3(0, 1.38, -0.02)), {
		"base_color": hair_color,
		"shadow_color": Color(0.02, 0.03, 0.05),
		"outline_width": 0.018,
	})
	topknot.mesh.top_radius = 0.05
	topknot.mesh.bottom_radius = 0.06
	topknot.mesh.height = 0.22
	root.add_child(topknot)

	var hair_bun = _styled(_mesh(SphereMesh.new(), Vector3(0, 1.48, -0.02), Vector3.ZERO, Vector3(1.0, 0.85, 1.0)), {
		"base_color": hair_color,
		"shadow_color": Color(0.02, 0.03, 0.05),
		"outline_width": 0.018,
	})
	hair_bun.mesh.radius = 0.08
	hair_bun.mesh.height = 0.12
	root.add_child(hair_bun)

	var band = _styled(_mesh(BoxMesh.new(), Vector3(0, 1.18, 0.02)), {
		"base_color": sash_color,
		"shadow_color": Color(0.20, 0.04, 0.04),
		"outline_width": 0.016,
	})
	band.mesh.size = Vector3(0.38, 0.04, 0.34)
	root.add_child(band)

	var band_tail_a = _styled(_mesh(BoxMesh.new(), Vector3(0.18, 1.10, -0.18), Vector3(deg_to_rad(8), deg_to_rad(14), deg_to_rad(-32))), {
		"base_color": sash_color,
		"shadow_color": Color(0.20, 0.04, 0.04),
		"outline_width": 0.016,
	})
	band_tail_a.mesh.size = Vector3(0.05, 0.30, 0.04)
	root.add_child(band_tail_a)

	var band_tail_b = _styled(_mesh(BoxMesh.new(), Vector3(0.24, 0.94, -0.26), Vector3(deg_to_rad(16), deg_to_rad(18), deg_to_rad(-20))), {
		"base_color": sash_color.lightened(0.06),
		"shadow_color": Color(0.20, 0.04, 0.04),
		"outline_width": 0.016,
	})
	band_tail_b.mesh.size = Vector3(0.04, 0.24, 0.03)
	root.add_child(band_tail_b)

	var shoulder_cloak = _styled(_mesh(BoxMesh.new(), Vector3(0.16, 0.74, -0.12), Vector3(deg_to_rad(10), 0, deg_to_rad(-18))), {
		"base_color": outfit_color.darkened(0.14),
		"shadow_color": cloth_shadow.darkened(0.12),
		"outline_width": 0.020,
	})
	shoulder_cloak.mesh.size = Vector3(0.08, 0.48, 0.26)
	root.add_child(shoulder_cloak)

	var sheath = _styled(_mesh(BoxMesh.new(), Vector3(-0.20, 0.78, -0.14), Vector3(deg_to_rad(4), deg_to_rad(10), deg_to_rad(24))), {
		"base_color": leather_color,
		"shadow_color": Color(0.07, 0.04, 0.03),
		"outline_width": 0.020,
	})
	sheath.mesh.size = Vector3(0.08, 0.78, 0.09)
	root.add_child(sheath)

	var handle = _styled(_mesh(BoxMesh.new(), Vector3(-0.02, 1.05, -0.02), Vector3(deg_to_rad(4), deg_to_rad(10), deg_to_rad(24))), {
		"base_color": cream_color.darkened(0.16),
		"shadow_color": Color(0.18, 0.16, 0.14),
		"outline_width": 0.018,
	})
	handle.mesh.size = Vector3(0.06, 0.26, 0.05)
	root.add_child(handle)

	var guard = _styled(_mesh(CylinderMesh.new(), Vector3(-0.06, 0.93, -0.06), Vector3(deg_to_rad(90), 0, deg_to_rad(24))), {
		"base_color": gold_color,
		"shadow_color": Color(0.36, 0.24, 0.06),
		"outline_width": 0.018,
	})
	guard.mesh.top_radius = 0.08
	guard.mesh.bottom_radius = 0.08
	guard.mesh.height = 0.03
	root.add_child(guard)

	var charm = _mesh(SphereMesh.new(), Vector3(0.22, 0.34, 0.20), Vector3.ZERO, Vector3(1.0, 0.85, 1.0))
	charm.mesh.radius = 0.05
	charm.mesh.height = 0.08
	root.add_child(charm)
	_mark_as_accent(charm, spirit_color, 2.6)

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

# ===================== HELPERS =====================

func _mesh(mesh_res: Mesh, pos: Vector3, rot: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh_res
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	return mi

func _styled(mi: MeshInstance3D, style: Dictionary) -> MeshInstance3D:
	mi.set_meta("style", style)
	return mi

func _mark_as_accent(mi: MeshInstance3D, color: Color = Color.WHITE, intensity: float = 3.0) -> void:
	## Marca mesh como "accent" — recebe material de glow em vez de cel-shader
	_styled(mi, {
		"glow": true,
		"glow_color": color,
		"glow_intensity": intensity,
	})

func apply_model_materials(root: Node3D, base_color: Color) -> void:
	## Aplica cel-shader a todos os meshes do modelo, glow nos accents
	for child in root.get_children():
		if child is MeshInstance3D:
			var style: Dictionary = child.get_meta("style", {})
			if style.get("glow", false):
				# Accent: olhos, orbes — glow branco/brilhante
				var mat = StandardMaterial3D.new()
				var glow_color: Color = style.get("glow_color", Color.WHITE)
				mat.albedo_color = glow_color
				mat.emission_enabled = true
				mat.emission = glow_color
				mat.emission_energy_multiplier = style.get("glow_intensity", 3.0)
				child.material_override = mat
			else:
				var mesh_color: Color = style.get("base_color", base_color)
				var settings := {}
				for key in ["rim_color", "rim_amount", "toon_steps", "shadow_color", "outline_color", "outline_width"]:
					if style.has(key):
						settings[key] = style[key]
				VisualSetup.apply_cel_shader_to_mesh(child, mesh_color, settings)

func get_model_for_character(char_id: String) -> Node3D:
	match char_id:
		"ronin": return create_ronin_model()
		"soldado": return create_soldado_model()
		"mago": return create_mago_model()
		"berserker": return create_berserker_model()
		"ninja": return create_ninja_model()
	return create_ronin_model()

func get_model_for_enemy(enemy_name: String) -> Node3D:
	match enemy_name:
		"Slime", "SlimeBig": return create_slime_model()
		"Bat": return create_bat_model()
		"Skeleton", "SkeletonArcher": return create_skeleton_model()
		"ZombieRunner": return create_zombie_model()
		"Ghost": return create_ghost_model()
		"Tank": return create_tank_model()
		"Bomber": return create_bomber_model()
		"BossNecromancer": return create_boss_model()
	return create_slime_model()
