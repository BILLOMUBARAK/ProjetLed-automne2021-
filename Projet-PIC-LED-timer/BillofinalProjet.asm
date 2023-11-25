;
; Daniel Audet
; Juillet 2010
;
;****************************************************************************
; MCU TYPE
;****************************************************************************
	LIST	p=18F4680     ; définit le numéro du PIC pour lequel ce programme sera assemblé

;****************************************************************************
; INCLUDES
;****************************************************************************
#include	 <p18f4680.inc>	;  La directive "include" permet d'insérer la librairie "p18f4680.inc" dans le présent programme.
				; Cette librairie contient l'adresse de chacun des SFR ainsi que l'identité (nombre) de chaque bit 
				; de configuration portant un nom prédéfini.

;****************************************************************************
; MCU DIRECTIVES   (définit l'état de certains bits de configuration qui seront chargés lorsque le PIC débutera l'exécution)
;****************************************************************************
    CONFIG	OSC = ECIO           
    CONFIG	FCMEN = OFF        
    CONFIG	IESO = OFF       
    CONFIG	PWRT = ON           
    CONFIG	BOREN = OFF        
    CONFIG	BORV = 2          
    CONFIG	WDT = OFF          
    CONFIG	WDTPS = 256       
    CONFIG	MCLRE = ON          
    CONFIG	LPT1OSC = OFF      
    CONFIG	PBADEN = OFF        
    CONFIG	STVREN = ON     
    CONFIG	LVP = OFF         
    CONFIG	XINST = OFF       
    CONFIG	DEBUG = OFF         
  

;************************************************************
ZONE1_UDATA	udata 0x60 	; La directive "udata" (unsigned data) permet de définir l'adresse du début d'une zone-mémoire
				; de la mémoire-donnée (ici 0x60).
				; Les directives "res" qui suivront, définiront des espaces-mémoire à partir de cette adresse.
				; La zone doit porter un nom unique (ici "ZONE1_UDATA") car on peut en définir plusieurs.
				
Count	 	res 1 		; La directive "res" réserve un seul octet qui pourra être référencé à l'aide du mot "Count".
				; L'octet sera localisé à l'adresse 0x60 (dans la banque 0).
DelaiRouge	res 1
DelaiVert       res 1
DelaiJaune	res 1
;************************************************************
; reset vector
 
Zone1	code 00000h		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone1".
				; Ici, l'instruction "goto" sera donc stockée à l'adresse 00000h dans la mémoire-programme. 
				
	goto Start		; Le micro-contrôleur saute à l'adresse-programme définie par l'étiquette "Start".

;************************************************************
; interrupt vector
 
Zone2	code	00008h		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone2".
				; Ici, l'instruction "btfss" sera donc stockée à l'adresse 00008h dans la mémoire-programme.
				;
				; NOTE IMPORTANTE: Lorsque le micro-contrôleur subit une interruption, il interrompt le programme
				;                  en cours et saute à l'adresse 00008h pour exécuter l'instruction qui s'y trouve.
				;                  
	
	btfsc INTCON,TMR0IF	; Teste la valeur du bit nommé "TMR0IF" de l'espace-mémoire associée à INTCOM. Ce bit est en fait 
				; le bit numéro 2 selon la description détaillée du micro-contrôleur PIC. 
				; Ainsi, si ce bit est à 1, le temporisateur 0 est bien la source de l'interruption.
				; Si ce bit est à 0 (clear), on sautera l'instruction suivante (call TO_ISR). 
	
	call TO_ISR		; Exécute la sous-routine débutant à l'adresse "TO_ISR"
	retfie			; Cette instruction force le retour à l'instruction qui a été interrompue lors de l'interruption.


;************************************************************
;program code starts here

Zone3	code 00020h		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 020h
				; Cette nouvelle zone de code est nommée "Zone3".

Start				; Cette étiquette précède l'instruction "bcf". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
	bcf TRISC,0		; définit le bit 1 du port C en sortie
	bcf TRISC,1		; définit le bit 1 du port C en sortie
	bcf TRISC,2		; définit le bit 2 du port C en sortie
	clrf TRISD		; définit tous les bits du port D en sorties
	setf TRISB		; définit tous les bits du port B en entrées 

	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count" 
	
	;Dans cette zone on charge les différentes valeurs au variable creer pour pouvoir gérer le temps 
	movlw 0x0e
	movwf DelaiRouge
	movlw 0xff
	movwf DelaiVert
	movlw 0xA0
	movwf DelaiJaune
	movlw 0x07		; Charge la valeur 0x07 dans le registre WREG
	movwf T0CON		; Copie le contenu du registre WREG dans l'espace-mémoire associé à T0CON
				; Ces 8 bits (00000111) configure le micro-contrôleur de telle
				; sorte que le temporisateur 0 soit actif, qu'il opère avec 16 bits,
				; qu'il utilise un facteur d'échelle ainsi que l'horloge interne
				; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw 0xff		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movlw 0xf2		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)
				
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.
				
	bsf T0CON,TMR0ON	; Met à 1 le bit appelé TMR0ON (bit 7 de l'espace-mémoire associé à T0CON)
				; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le temporisateur 0 est donc démarré.
				
	bsf INTCON,TMR0IE	; Met à 1 le bit appelé TMR0IE (bit 5 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise le temporisateur à interrompre le micro-contrôleur lorsque le temporisateur viendra à échéance (00000000).
				
	bsf INTCON,GIE		; Met à 1 le bit appelé GIE (bit 7 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont été validées.

loop
	;btg PORTC,		; Inverse ("toggle") la valeur courante du bit 2 stocké dans l'espace-mémoire associé au port C
	movff PORTB,PORTD	; Copie le contenu du port B dans le port D
	bra loop		; Saute à l'adresse "loop" (soit l'adresse de l'instruction "btg")

Zone4	code 0x100		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 0x100
				; Cette nouvelle zone de code est nommée "Zone4".

TO_ISR	
decf Count		; décrémente le contenu de l'espace-mémoire associé à "Count"
bnz saut		; saute à l'adresse associée à "saut" si le bit Z du registre de statut est à 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").	
goto Delai
saut
	return			; Provoque le retour à l'instruction suivant l'appel de la sous-routine 
Delai
; on vérifie si le feu vert est allumé on l'eteint on execute la sous routine permettant d'allumer le feu jaune
	btfsc PORTC,0		 
	goto AllumeJaune
	
; si le feu vert n'est pas  allumé  on execute la sous routine pour aller vérifier quel feu est allumé    
	btfss PORTC,0
	
	goto FeuAllume
	
        return
FeuAllume
; on vérifie si le feu jaune est allumé on l'eteint on execute la sous routine permettant d'allumer le feu Rouge	
	btfsc PORTC,1
	goto AllumeRouge
; on vérifie si le feu rouge est allumé on l'eteint on execute la sous routine permettant d'allumer le feu vert
	btfsc PORTC,2
	goto AllumeVert
	goto AllumeVert
	
; On execute sur cette partie une sous routine qui permet d'allumer le feu Vert
AllumeVert
	movlw 0xAf		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movff DelaiVert,TMR0L
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.
	
	goto VertAllume
	retfie
	
VertAllume
	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count"
	bcf PORTC,1
	bcf PORTC,2                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
	btg PORTC,0

	 
	return
	
; On execute sur cette partie une sous routine qui permet d'allumer le feu Jaune
AllumeJaune
	movlw 0xe8		; Charge la valeur 0xef dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movff DelaiJaune,TMR0L
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.
	bsf INTCON,GIE
	goto JauneAllume
	retfie
	
JauneAllume
	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count" 
	bcf PORTC,0
	bcf PORTC,2
	btg PORTC,1
	
	return
	
; On execute sur cette partie une sous routine qui permet d'allumer le feu Rouge
AllumeRouge
	movlw 0x8f		; Charge la valeur 0x8f dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movff DelaiRouge,TMR0L
	bcf INTCON,TMR0IF
	bsf INTCON,GIE
	goto RougeAllume
	
	retfie
	
RougeAllume
	movlw 0x3f		; charge la valeur 0x3f dans le registre WREG
	movwf Count		; copie le contenu du registre WREG dans l'espace-mémoire associé à "Count" 
	bcf PORTC,1
	bcf PORTC,1
	btg PORTC,2
	
	return
	END



	


	
