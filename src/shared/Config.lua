local Config = {
	GameName = "The High Society Club",
	CurrencyName = "Society Credits",
	AdminUserIds = {},
	AdminAllowExperienceCreator = true,
	DataStore = {
		Name = "EconomyData_v1",
		MaxRetries = 3,
		AutosaveInterval = 60,
		SessionLockTtl = 180,
		SessionLockWait = 35,
	},
	Economy = {
		MaxCurrency = 2_000_000_000,
		MaxTransactions = 100,
		WelcomeBonus = 250,
	},
	Vehicles = {
		TestDriveDuration = 30,
	},
	Club = {
		MusicSoundId = "",
		DJBoothAccessDuration = 300,
		MaxPerformanceDuration = 180,
	},
	RateLimits = {
		RequestCooldown = 1,
		QueryCooldown = 0.5,
		MarketQueryCooldown = 0.5,
		MarketActionCooldown = 1,
		CreationQueryCooldown = 2,
		CreationReviewCooldown = 2,
		CreationSubmitCooldown = 5,
		SpawnCooldown = 2,
		EventCatalogCooldown = 0.75,
		WorkRequestCooldown = 0.5,
		EventInviteCooldown = 1.5,
		EventInviteResponseCooldown = 1,
		FashionContestCooldown = 1,
		ClubPerformanceCooldown = 1,
		AdminActionCooldown = 2,
		VehicleControlCooldown = 0.075,
	},
	Market = {
		TransferDistance = 20,
		MaxListingPrice = 100_000,
		MaxDonation = 100_000,
		SaleCommissionPercent = 5,
		MaxListingsPerPlayer = 5,
		MaxActiveListings = 100,
		ListingDuration = 900,
	},
	Monetization = {
		VIPGamePassId = 0,
		DeveloperProducts = {
			{ Id = 0, Name = "1.000 Society Credits", Credits = 1_000 },
			{ Id = 0, Name = "5.000 Society Credits", Credits = 5_000 },
			{ Id = 0, Name = "20.000 Society Credits", Credits = 20_000 },
		},
	},
	CreationModeration = {
		DataStoreName = "CreationModeration_v1",
		MaxStoredSubmissions = 100,
		MaxPublicCreations = 20,
	},
	DayNight = {
		-- true: o dia e a noite seguem o relógio real (fuso abaixo).
		-- false: ciclo acelerado de 24 minutos.
		UseRealTime = true,
		UTCOffsetHours = -3, -- Brasília
	},
	World = {
		-- Visitantes (NPCs) que passeiam pela cidade para dar vida ao mundo.
		NpcCount = 12,
		-- Opcional: IDs de imagens (decals) enviadas por você ao Roblox para os outdoors.
		-- Exemplo: { 123456789, 987654321 }. Vazio = outdoors com o slogan do jogo.
		BillboardImageIds = {},
		-- Auditoria automática do mundo gerado (relatório no Output).
		AuditOnStart = true,
		AuditOnlyInStudio = true,
		-- Larguras das ruas e calçadas. O WorldBuilder usa estes valores tanto
		-- na geração nova quanto no alargamento não destrutivo de um mundo
		-- que já esteja salvo no Studio.
		Streets = {
			-- Suba a versão quando as medidas mudarem, para o passe de
			-- alargamento ser aplicado uma vez no mundo existente.
			Version = 1,
			MainRoadWidth = 36,
			MainSidewalkWidth = 10,
			PromenadeWidth = 16,
			GardenWalkWidth = 12,
			IslandPromenadeWidth = 11,
			BeachPromenadeWidth = 8,
			MarinaPromenadeWidth = 10,
			FrontRoadWidth = 34,
			FrontSidewalkWidth = 9,
			ConnectorWidth = 16,
			EntrancePathWidth = 12,
		},
	},
	Safety = {
		-- Resgate automático e silencioso de personagens presos.
		-- Não há botão nem interface: o jogador é levado ao spawn seguro
		-- somente quando fica empurrando uma parede sem sair do lugar.
		Enabled = true,
		AutoUnstuckEnabled = true,
		-- Tempo parado empurrando uma parede antes do resgate automático.
		AutoUnstuckSeconds = 5,
		CheckInterval = 0.5,
	},
	Map = {
		WorldName = "HighSocietyWorld",
		BaseplateName = "Baseplate",
		SpawnLocationName = "SpawnLocation",
	},
}

return Config
