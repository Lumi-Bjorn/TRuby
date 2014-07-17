require 'gosu'

$: << "."

require 'lib/map'
require 'lib/player'
require 'lib/bomb'
require 'lib/powerup'
require "lib/constants"
require "lib/explosion"
require "lib/parameter"

require 'lib/gamemethods'
require 'lib/statemanager'
require 'lib/checkers'
require 'lib/drawers'
require 'lib/printers'
require 'lib/updaters'
require 'lib/server'
require 'lib/client'

class Game < Gosu::Window

	include TRuby::GameMethods
	include TRuby::StateManager
	include TRuby::Printers
	include TRuby::Drawers
	include TRuby::Updaters
	include TRuby::Checkers
	include TRuby::Server
	include TRuby::Client

	attr_reader :map

	def initialize(width=WIDTH, height=HEIGHT, actualState=nil)

		debug "[GAME] Init base variables"

		super width, height, false

		@moveUp = false
		@moveDown = false
		@moveLeft = false
		@moveRight = false
		@bombPut = false
		@enterPressed = false
		@client = nil

		@num_actual_player = 0
		@nbPlayers = 0
		@players = Array.new
		@port = 32456

		@keyNum1 = false

		@stateMustBeChanged = false
		@isServer = false
		@initializePlaying = true

		@mut = Mutex.new
		@mutexPlayerDatas = Mutex.new

		debug "[GAME] Init fonts"

		@font_window = Gosu::Font.new(self, "fonts/BlissfulThinking.otf", 18)
		@font_window_big = Gosu::Font.new(self, "fonts/BlissfulThinking.otf", 26)
		@font_window_title = Gosu::Font.new(self, "fonts/BlissfulThinking.otf", 40)

		if (actualState == nil)
			@actualState = STATE_MENU
			initializeMenu
		end
	end

	def initializeMenu
		debug "[GAME] Init Menu"
		self.caption = 'TRuby - Selection'

		@mouseShown = true
		@isServer = false

		@menuItems = ["Create Server", "Join Server", "Quit"]

		debug "[GAME] Init Images"
		@image_background = Gosu::Image.new(self, "img/menu/background.png", false)
		@image_background_map_selection = Gosu::Image.new(self, "img/menu/background_map_selection.png", false)

		@selection = SELECTION_CREATE_SERVER
	end

	def initializeMapSelection

		debug "[GAME] Init Map Selection"
		self.caption = "TRuby - Selection de la carte"

		@mouseShown = true
		@isServer = true

		debug "[GAME] Listing maps"
		listMaps

		@selection = 0

	end

	def initializeParamsSelection
		debug "[GAME] Init Params Selection"
		self.caption = "TRuby - Parametrage"

		debug "[GAME] Loading map"
		begin
			@map.readFile
		rescue
			debug "[ERROR] Loading map"
		end

		puts @isServer
		if (@isServer)
			@paramsItems = [TRuby::Parameter.new("Play !", nil), TRuby::Parameter.new("Port", 32456, 0, 65536), TRuby::Parameter.new("Nombre de joueurs", @map.nbPlayers, 1, @map.nbPlayers)]
		else
			@paramsItems = [TRuby::Parameter.new("Play !", nil), TRuby::Parameter.new("IP", "<Enter IP>"), TRuby::Parameter.new("Port", 32456, 0, 65536)]
		end

		@keyboardIn = false

		@selection = 0
	end

	def initializeWaiting
		debug "[GAME] Init Waiting Screen"

		@image_window = Gosu::Image.new(self, "img/menu/window.png", false)
	end

	def initializePlaying
		debug "[GAME] Init Play"
		@mouseShown = false

		debug "[GAME] Loading map"
		begin
			@map.readFile
		rescue
			debug "[ERROR] Loading map"
		end

		self.caption = 'TRuby - Playing'

		debug "[GAME] Init Images"
		@image_mur = Gosu::Image.new(self, "img/mur.png", false)
		@image_bomb = Gosu::Image.new(self, "img/bomb.png", false)
		@image_void = Gosu::Image.new(self, "img/void.png", false)
		@image_fireup = Gosu::Image.new(self, "img/fireup.png", false)
		@image_bombup = Gosu::Image.new(self, "img/bombup.png", false)
		@image_timeup = Gosu::Image.new(self, "img/timeup.png", false)
		@image_player = Gosu::Image.new(self, "img/player.png", false)
		@image_explosion = Gosu::Image.new(self, "img/explosion.png", false)

		debug "[GAME] Init Variables"

		debug "[GAME] Num_actual_player : #{@num_actual_player}"
		@mutexPlayerDatas.synchronize do
			@player = TRuby::Player.new(@map.getXSpawn(@num_actual_player), @map.getYSpawn(@num_actual_player), @map.width, @map.height)
			@players[@num_actual_player] = @player
			sendPlayerInit(@num_actual_player, @player.x, @player.y)
		end

		@bombs = Hash.new(nil)
		@powerups = Hash.new(nil)
		@explosions = Array.new
		
		@dx = 1.0 * WIDTH / (@map.width * @map.tile_size)
		@dy = 1.0 * HEIGHT / (@map.height * @map.tile_size)

		@initializePlaying = false
	end

	def update
		case getActualState()
		when STATE_MENU
			updateMenu
		when STATE_PLAYING
			updatePlaying
		when STATE_WAITING_SERVER
			updateWaitingServer
		when STATE_WAITING_CLIENT
			updateWaitingClient
		when STATE_MAP_SELECTION
			updateMapSelection
		when STATE_PARAMS_SELECTION
			updateParamsSelection
		end

		checkState
	end

	def draw
		case getActualState()
		when STATE_MENU
			drawMenu
		when STATE_PLAYING
			drawPlaying
		when STATE_WAITING_SERVER
			drawWaitingServer
		when STATE_WAITING_CLIENT
			drawWaitingClient
		when STATE_MAP_SELECTION
			drawMapSelection
		when STATE_PARAMS_SELECTION
			drawParamsSelection
		end
	end

	def close
		leaveServer

		if (@isServer)
			stopServer
		end

		super
	end

	def debug(message)
		puts message
	end
end


window = Game.new
window.show
window.close