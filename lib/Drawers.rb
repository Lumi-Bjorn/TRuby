

module TRuby::Drawers

	def drawMenu
		printBackgroundMenu
		printItemsMenu
		
	end

	def drawPlaying
		printMap
		
		printPlayers
		printBombs
		printPowerUps

		printExplosions

		printHUD
	end

	def drawMapSelection
		printBackgroundMapSelection

		printMapSelectionTitle
		printMapsList
	end

	def drawParamsSelection
		printBackgroundMapSelection

		printParamsSelectionTitle
		printParamsItems
	end

	def drawWaitingServer
		printWindowMessage("Waiting server ...")
	end

	def drawWaitingClient
		printWindowMessage("Waiting clients ...")
	end

	def drawEndRound
		printBackgroundMapSelection

		printEndRoundTitle
		printEndRoundItems
	end

end