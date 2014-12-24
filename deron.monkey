Import mojo

Const DOWN_ACCELERATION:Float = 1500 ' Vertical pixels per second per second
Const SPEED:Float = 420             ' Horizonal pixels per second
Const SCENE_LEFT:Float = 0
Const SCENE_RIGHT:Float = 640

Function RectsOverlap:Int(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float)
 	If x1 > (x2 + w2) Or (x1 + w1) < x2 Then Return False
 	If y1 > (y2 + h2) Or (y1 + h1) < y2 Then Return False
	Return True
End

Function RectIntersection:Float[](x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float)
	' Get the right and bottom coordinates
	Local r1:Float = x1 + w1
	Local r2:Float = x2 + w2
	Local b1:Float = y1 + h1
	Local b2:Float = y2 + h2
	
	' Find intersection.
	Local xL:Float = Max(x1, x2)
	Local xR:Float = Min(r1, r2)

	If xR <= xL
	    Return []
	Else
	    Local yT:Float = Max(y1, y2)
	    Local yB:Float = Min(b1, b2)
	    If yB <= yT Then Return []
	    Return [xL, yT, xR - xL, yB - yT]
	End
End

' Landing from above is true if the intersecting rectangle is horizontal.
Function LandingFromAbove:Bool(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float)
	Local intersectingRect:Float[] = RectIntersection(x1, y1, w1, h1, x2, y2, w2, h2)
	
	' intersectingRect[2] is width.
	' intersectingRect[3] is height.
	' If width > height, it's horizontal intersection, so we are landing from above.
	Return intersectingRect[2] > intersectingRect[3]
End

Class DeronsGreatAdventure Extends App 
	Field deron:Image
	Field deronX:Float = 158
	Field deronY:Float = 24
	
	Field nored:Image
	Field noredX:Float = 450
	Field noredY:Float

	Field fallingVelocity:Float = 0.0
	Field lastJumpInAir:Bool = False
	Field ms:Int
	Field deronAngle:Float
	
	Method OnCreate()
		SetUpdateRate 60
		deron = LoadImage("Deron.png", 1, Image.MidHandle)
		nored = LoadImage("Nored.png", 1, Image.MidHandle)
		noredY = 400 - nored.Height / 2
		ms = Millisecs
	End
	
	Method OnUpdate()
		Local elapsed:Int = Millisecs - ms
		
		' Move left and right
		deronX += KeyDown(KEY_RIGHT) * SPEED * (elapsed / 1000.0)
		deronX -= KeyDown(KEY_LEFT) * SPEED * (elapsed / 1000.0)
			
		' Don't hit the walls
		deronX = Max(deronX, SCENE_LEFT  + deron.Width / 2)
		deronX = Min(deronX, SCENE_RIGHT - deron.Width / 2)
		
		' Jump
		Local inAir:Bool = deronY + deron.Height < 400
		If KeyHit(KEY_UP)
	    	If Not lastJumpInAir Or Not inAir
				fallingVelocity = -700
				lastJumpInAir = inAir
			End
		End

		' Wobble
		If Not KeyDown(KEY_LEFT) And Not KeyDown(KEY_RIGHT) And Not inAir
			deronAngle = Cos(ms) * 3
		End

		' Fall with gravity
		fallingVelocity = fallingVelocity + DOWN_ACCELERATION / 1000.0 * elapsed
		deronY = deronY + fallingVelocity / 1000.0 * elapsed
		
		' Don't go below ground
		If deronY + deron.Height / 2 >= 400
			fallingVelocity = -fallingVelocity / 3 ' Bounce
			lastJumpInAir = False
			deronY = 400 - deron.Height / 2        ' Teleport Deron above the ground
		End
		
		' Bounce off Nored
		If RectsOverlap(deronX - deron.Width / 2, deronY - deron.Height / 2, deron.Width, deron.Height,
						noredX - nored.Width / 2, noredY - nored.Height / 2, nored.Width, nored.Height)
			fallingVelocity = -600
			
			If LandingFromAbove(deronX - deron.Width / 2, deronY - deron.Height / 2, deron.Width, deron.Height,
								noredX - nored.Width / 2, noredY - nored.Height / 2, nored.Width, nored.Height)
				deronY = noredY - (nored.HandleY + deron.HandleY) - 1
				lastJumpInAir = False
			Elseif KeyDown(KEY_RIGHT)
				deronX = noredX - (nored.HandleX + deron.HandleX) - 1
			Elseif KeyDown(KEY_LEFT)
				deronX = noredX + (nored.HandleX + deron.HandleX) + 1
			End
		End
	
		ms += elapsed
	End

	Method OnRender()
		Cls 155, 255, 255

		' Draw the sun
		SetColor 255, 255, 0
		DrawCircle 130, 140, 75
		
		' Draw Deron
		SetColor 255, 255, 255
		DrawImage deron, deronX, deronY, deronAngle, 1, 1

		' Draw Nored
		SetColor 255, 255, 255
		DrawImage nored, noredX, noredY
		
		' Draw the ground
		SetColor 0, 153, 0
		DrawRect 0, 400, 640, 80
	End

	Method OnResume()
		' Ignore time that passed while suspended. 
		' This prevents the crazy bunny bounce when the game resumes.
		ms = Millisecs
	End
End

Function Main()
	New DeronsGreatAdventure
End