AddCSLuaFile()

if not Glide then return end

ENT.GlideCategory = "GTAV_Helicopters"

ENT.Type = "anim"
ENT.Base = "glide_gtav_armed_heli"
ENT.PrintName = "UH60 - M134"

ENT.MainRotorOffset = Vector( 3.5, 0, 140 )
ENT.TailRotorOffset = Vector( -370, -15, 145 )
ENT.TailRotorAngle = Angle( 0, 0, -15 )

Glide.MAX_SEATS = 10

DEFINE_BASECLASS( "base_glide_heli" )

function ENT:SetupDataTables()
    -- Call the base class' `SetupDataTables`
    -- to let it setup required network variables.
    BaseClass.SetupDataTables( self )

    -- Store our turret entity, as well as the seat that controls it.
    self:NetworkVar( "Entity", "TurretLeft" )
    self:NetworkVar( "Entity", "TurretSeatLeft" )

    self:NetworkVar( "Entity", "TurretRight" )
    self:NetworkVar( "Entity", "TurretSeatRight" )
end

if CLIENT then
    local turretClientL = nil
    local turretClientR = nil

    ENT.CameraOffset = Vector( -800, 0, 180 )
    ENT.MidSoundVol = 0.5

    ENT.ExhaustPositions = {
        Vector( -88, 45, 100 ),
        Vector( -88, -45, 100 )
    }

    ENT.EngineFireOffsets = {
        { offset = Vector( -88, -45, 100 ), angle = Angle( 300, 0, 0 ), scale = 1.0 },
        { offset = Vector( -88, 45, 100 ), angle = Angle( 300, 0, 0 ), scale = 1.0 }
    }

    ENT.CrosshairInfo = {
        { iconType = "dot" }
    }


    function ENT:OnLocalPlayerEnter( seatIndex )
        self:DisableCrosshair()

        -- Enable the crosshair when a player enters the turret seat
        if seatIndex == 3 or seatIndex == 4 then
            self:EnableCrosshair( { iconType = "dot", color = Color( 122, 255, 129), size = 0.02 } )
        else
            -- Let the base class handle it
            BaseClass.OnLocalPlayerEnter( self, seatIndex )
        end
    end

    function ENT:OnLocalPlayerExit()
        self:DisableCrosshair()
    end

    -- This function runs every frame when the crosshair is enabled.
    function ENT:UpdateCrosshairPosition()
        -- Put right at the local player's camera aim position.
        self.crosshair.origin = Glide.GetCameraAimPos()
    end

    function ENT:OnActivateMisc()
        -- Let the base class do some initialization
        BaseClass.OnActivateMisc( self )

        -- Store the bones that control the turret's base and weapon
        self.turretBaseBoneL = self:LookupBone( "m134_yaw_l" )
        self.turretWeaponBoneL = self:LookupBone( "m134_pitch_l" )

        self.turretBaseBoneR = self:LookupBone( "m134_yaw_r" )
        self.turretWeaponBoneR = self:LookupBone( "m134_pitch_r" )

        turretClientL = self:GetTurretLeft()
        turretClientR = self:GetTurretRight()

        local turrets = {
            turretClientL,
            turretClientR
        }

        for i, gun in ipairs( turrets ) do
            gun.ViewpunchMultiplier = -1
            gun.ViewpunchDelay = 0.02
            gun.ViewpunchRange = 0.60
        end
    end

    -- Temporary variables to move/rotate the turret's bones
    local ang = Angle()

    function ENT:OnUpdateAnimations()
        -- Call the base class' `OnUpdateAnimations`
        -- to automatically update the steering pose parameter.
        BaseClass.OnUpdateAnimations( self )

        turretClientL = self:GetTurretLeft()
        if not IsValid( turretClientL ) then return end

        local bodyAngL = turretClientL:GetLastBodyAngle()

        if not self.turretBaseBoneL then return end
        -- Using the turret's body angle,
        -- rotate our turret base/weapon bones.
        bodyAngL[1] = math.NormalizeAngle( bodyAngL[1] ) -- Stay on the -180/180 range

        ang[1] = bodyAngL[2] - 90
        ang[2] = 0
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretBaseBoneL, ang )

        ang[1] = 0
        ang[2] = -bodyAngL[1]
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretWeaponBoneL, ang )

        --------------------------------------------

        local turretR = self:GetTurretRight()
        if not IsValid( turretR ) then return end

        local bodyAngR = turretR:GetLastBodyAngle()

        if not self.turretBaseBoneR then return end

        -- Using the turret's body angle,
        -- rotate our turret base/weapon bones.
        bodyAngR[1] = math.NormalizeAngle( bodyAngR[1] ) -- Stay on the -180/180 range

        ang[1] = bodyAngR[2] + 90
        ang[2] = 0
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretBaseBoneR, ang )

        ang[1] = 0
        ang[2] = bodyAngR[1]
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretWeaponBoneR, ang )
    end

    -- Override the default camera type for the turret seat
    function ENT:GetCameraType( seatIndex )
        return seatIndex == 3 or seatIndex == 4 and 1 or 0 -- Glide.CAMERA_TYPE.TURRET or Glide.CAMERA_TYPE.CAR
    end

    function ENT:GetFirstPersonOffset( seatIndex, localEyePos )
        if seatIndex == 3 then
            localEyePos[2] = localEyePos[2] + 5
            localEyePos[3] = localEyePos[3] + 2
        elseif seatIndex == 4 then
            localEyePos[2] = localEyePos[2] - 8
        end

        localEyePos[3] = localEyePos[3] + 5

        return localEyePos
    end

    -- Don't muffle sounds while sitting on the turret seat,
    -- or on the rear exterior seats.
    function ENT:AllowFirstPersonMuffledSound( seatIndex )
        if seatIndex == 3 or seatIndex == 4 then
            return false
        end
        return true
    end

    local POSE_DATA1 = {
        ["ValveBiped.Bip01_L_UpperArm"] = Angle( 0, 0, 0),
        ["ValveBiped.Bip01_L_Forearm"] = Angle( 0, -0, -0 ),
        ["ValveBiped.Bip01_R_UpperArm"] = Angle( 0, 0, -0 ),
        ["ValveBiped.Bip01_R_Forearm"] = Angle( -0, -0, 0 ),

        ["ValveBiped.Bip01_L_Foot"] = Angle( 0, 0, -15 ),
        ["ValveBiped.Bip01_R_Foot"] = Angle( 0, -0, 15 ),

        ["ValveBiped.Bip01_L_Thigh"] = Angle( -20, -10, 10 ),
        ["ValveBiped.Bip01_L_Calf"] = Angle( -5, 40, 10 ),

        ["ValveBiped.Bip01_R_Thigh"] = Angle( 20, -10, -10 ),
        ["ValveBiped.Bip01_R_Calf"] = Angle( 5, 40, -10 ),

        ["ValveBiped.Bip01_Spine1"] = Angle( -0, -0, -0 ),
    }

    function ENT:GetSeatBoneManipulations( seatIndex )
        if seatIndex == 3 or seatIndex == 4 then
            return POSE_DATA1
        end
    end
end


if SERVER then
    ENT.ChassisMass = 800
    ENT.ChassisModel = "models/glide/glide_uh60_blackhawk/uh-60_fuselage.mdl"

    ENT.MainRotorRadius = 320
    ENT.TailRotorRadius = 64

    ENT.MainRotorModel = "models/glide/glide_uh60_blackhawk/uh-60_main.mdl"
    ENT.MainRotorFastModel = "models/glide/glide_uh60_blackhawk/uh-60_main.mdl"

    ENT.TailRotorModel = "models/glide/glide_uh60_blackhawk/uh-60_tailrotor.mdl"
    ENT.TailRotorFastModel = "models/glide/glide_uh60_blackhawk/uh-60_tailrotor.mdl"

    ENT.ExplosionGibs = {
        "models/gta5/vehicles/gibs/annihilator_gib1.mdl",
        "models/gta5/vehicles/gibs/annihilator_gib2.mdl"
    }

    ENT.HelicopterParams = {
        pitchForce = 600,
        yawForce = 640,
        rollForce = 600,
        uprightForce = 200,
        maxRoll = 50,
        pushUpForce = 300
    }

    ENT.AngularDrag = Vector( -16, -25, -15) -- roll pitch yaw

    function ENT:InitializePhysics()
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:PhysicsInit( SOLID_VPHYSICS, Vector( 0, 0, 60 ) )
    end

    function ENT:CreateFeatures()

        self:CreateSeat( Vector( 110, -27, 40 ), nil, Vector( 140, 120, 0 ), true )
        self:CreateSeat( Vector( 110, 27, 40 ), nil, Vector( 140, -120, 0 ), true )

        local turretSeatLeft = self:CreateSeat( Vector( 66, 25, 37 ), Angle( 0, 0, 0 ), Vector( -30, 90, 0 ), true )
        local turretBonePosL = WorldToLocal( self:GetBonePosition( self:LookupBone( "m134_pitch_l") ), Angle(), self:GetPos(), self:GetAngles() )
        local turretLeft = Glide.CreateCustomTurret( "glide_zg_heavy_turret", self, turretBonePosL, Angle( 0, 0, 0 ) )

        self:SetTurretLeft( turretLeft )
        self:SetTurretSeatLeft( turretSeatLeft )

        turretLeft:SetFireDelay( 0.05 )
        turretLeft:SetBulletOffset( Vector( 35, 4, 0 ) )
        turretLeft:SetMinPitch( -40 )
        turretLeft:SetMaxPitch( 20 )
        turretLeft:SetMaxYaw( 180 )
        turretLeft:SetMinYaw( 0 )

        local turretSeatRight = self:CreateSeat( Vector( 66, -25, 37 ), Angle( 0, 180, 0 ), Vector( -30, 90, 0 ), true )
        local turretBonePosR = WorldToLocal( self:GetBonePosition( self:LookupBone( "m134_pitch_r") ), Angle(), self:GetPos(), self:GetAngles() )
        local turretRight = Glide.CreateCustomTurret( "glide_zg_heavy_turret", self, turretBonePosR, Angle( 0, 0, 0 ) )

        self:SetTurretRight( turretRight )
        self:SetTurretSeatRight( turretSeatRight )

        turretRight:SetFireDelay( 0.05 )
        turretRight:SetBulletOffset( Vector( 35, 3, 0 ) )
        turretRight:SetMinPitch( -40 )
        turretRight:SetMaxPitch( 20 )
        turretRight:SetMaxYaw( 0 )
        turretRight:SetMinYaw( -180 )

        local turrets = {
            turretLeft,
            turretRight
        }

        for i, gun in ipairs( turrets ) do
            gun:SetShootLoopSound( "glide/glide_uh60_blackhawk/m134_shoot.wav" )
            gun:SetShootStopSound( "glide/glide_uh60_blackhawk/m134_stop.wav" )

            gun:SetShellCasingsEjectForward( true )
            gun:SetShellCasingsOffset( Vector( -4, 36, -10 ) )

            gun.spinSpeed = 0
            gun.spinAngle = Angle()
            gun.BulletDamage = 20

            Glide.HideEntity( gun, true )
            Glide.HideEntity( gun:GetGunBody(), true )
        end

        self:CreateSeat( Vector( 0, -27, 37 ), Angle( 0, 90, 0 ), Vector( -30, 90, 0 ), true )
        self:CreateSeat( Vector( 0, -9, 37 ), Angle( 0, 90, 0 ), Vector( -30, 90, 0 ), true )
        self:CreateSeat( Vector( 0, 9, 37 ), Angle( 0, 90, 0 ), Vector( -30, 90, 0 ), true )
        --self:CreateSeat( Vector( 0, 27, 37 ), Angle( 0, 90, 0 ), Vector( -30, 90, 0 ), true )

        self:CreateSeat( Vector( -50, 27, 37 ), Angle( 0, -90, 0 ), Vector( -30, 90, 0 ), true )
       --self:CreateSeat( Vector( -55, 9, 36 ), Angle( 0, -90, 0 ), Vector( -30, 90, 0 ), true )
        self:CreateSeat( Vector( -50, -9, 36 ), Angle( 0, -90, 0 ), Vector( -30, 90, 0 ), true )
        self:CreateSeat( Vector( -55, -27, 37 ), Angle( 0, -90, 0 ), Vector( -30, 90, 0 ), true )
    end

    function ENT:UpdateTurretBarrel( turret, turretBone )
        local dt = FrameTime()

        turret.spinSpeed = Lerp( dt * 5, turret.spinSpeed, turret:GetIsFiring() and 1200 or 0 )
        turret.spinAngle[3] = ( turret.spinAngle[3] + dt * turret.spinSpeed ) % 360

        self:ManipulateBoneAngles( self:LookupBone(turretBone), turret.spinAngle )
    end

    function ENT:OnUpdateFeatures()
        local turretLeft = self:GetTurretLeft()
        local turretRight = self:GetTurretRight()

        self:UpdateTurretBarrel( turretLeft, "m134_barrel_l" )
        self:UpdateTurretBarrel( turretRight, "m134_barrel_r" )

        if IsValid( turretLeft ) then
            -- The player on our "turret seat" should be the user of the actual turret entity.
            turretLeft:UpdateUser( self:GetSeatDriver( 3 ) )
        end

        if IsValid( turretRight ) then
            -- The player on our "turret seat" should be the user of the actual turret entity.
            turretRight:UpdateUser( self:GetSeatDriver( 4 ) )
        end
    end

    function ENT:GetSpawnColor()
        return Color( 255, 255, 255)
    end
end