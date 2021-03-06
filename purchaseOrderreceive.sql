USE [POSDB]
GO
/****** Object:  StoredProcedure [dbo].[spWSPurchaseOrderReceive]    Script Date: 7/21/2018 3:57:59 PM ******/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES 
           WHERE ROUTINE_NAME = 'xx_spWSPurchaseOrderReceive' 
             AND ROUTINE_SCHEMA = 'dbo' 
             AND ROUTINE_TYPE = 'PROCEDURE')
  DROP PROCEDURE dbo.xx_spWSPurchaseOrderReceive
GO


CREATE PROCEDURE [dbo].[xx_spWSPurchaseOrderReceive](
@InvoiceNumber VARCHAR(35)
)
AS

DECLARE

@dateprocessed datetime;

BEGIN

	SET NOCOUNT ON;
    
	DECLARE @ItemID INT, @ScanCode VARCHAR(20), @ItemOrIng VARCHAR(15),@rcvd_count int;
	DECLARE @ItemName VARCHAR(60), @VPN VARCHAR(30), @ISize VARCHAR(20), @AInCase MONEY, @CaseOrder MONEY
	DECLARE @CaseCost MONEY, @QtyOrder MONEY, @TotalUnit MONEY, @TotalCost MONEY
	DECLARE  @CostPerUnit MONEY, @OUnitCost MONEY, @UnitCost MONEY

	DECLARE PO_RECEIVE_CUR CURSOR FOR
	SELECT ItemID, ScanCode, ItemOrIng, ItemIngName, VPN, AInCase, CaseOrder, CaseCost, QtyOrder,
	TotalUnit, TotalCost, OUnitCost, CostPerUnit
	FROM PurchaseOrderDetail 
	WHERE UPPER(InvoiceNumber) = UPPER(@InvoiceNumber)
	AND Status in('RCV', 'RCVDIR', 'RCV-MOD', 'RCVDIR-MOD')

	OPEN PO_RECEIVE_CUR
	FETCH NEXT FROM PO_RECEIVE_CUR INTO @ItemID, @ScanCode, @ItemOrIng, @ItemName, @VPN, 
	@AInCase, @CaseOrder, @CaseCost, @QtyOrder, @TotalUnit, @TotalCost, @OUnitCost, @UnitCost

	UPDATE xx_runningstatus set sts = 0, rcvd_count = 0;

	SET @rcvd_count = 0
	SET @dateprocessed = GETDATE()

	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			DECLARE @TDate DATETIME
			DECLARE @ACost MONEY, @OCaseCost MONEY
			
			SELECT @TDate = GETDATE()

			IF @ItemOrIng = 'ITEM'
				BEGIN
					IF (SELECT SUM(TotalUnit) FROM PurchaseOrderDetail WHERE ItemID = @ItemID AND TotalUnit > 0) > 0 
						SELECT @ACost = ABS((SELECT SUM(TotalCost) / SUM(TotalUnit) 
						FROM PurchaseOrderDetail 
						WHERE ItemID = @ItemID AND TotalUnit > 0))
					ELSE
						SELECT @ACost = 0
						
					IF @OUnitCost <> ABS(@TotalCost)/ABS(@TotalUnit)
						/*EAM 2017/06/26 Zero Cost start */
						IF ABS(@TotalCost) > 0
						/*EAM 2017/06/26 Zero Cost end */	
							INSERT INTO ItemPriceDetails(ItemID, LastCost, CurrentCost, AvgCost, TTime)
							VALUES(@ItemID,CASE WHEN @OUnitCost > 0 THEN @OUnitCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END,
							ABS(@TotalCost) / ABS(@TotalUnit), @ACost, @TDate)
						
					IF @AInCase > 0 
						BEGIN
							IF @QtyOrder > 0
								IF @CaseOrder > 0
									BEGIN
										
										IF @TotalCost=0
											BEGIN
												--PRINT '@AInCase > 0  @QtyOrder > 0  @CaseOrder > 0  con @CaseCost=0 AND @UnitCost=0'
												UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit
												WHERE ItemID = @ItemID
											END
										ELSE
											BEGIN
												--PRINT '@AInCase > 0  @QtyOrder > 0  @CaseOrder > 0  con @CaseCost<>0 AND @UnitCost<>0'
												SELECT @OCaseCost = (SELECT CaseCost FROM Iteminfo WHERE ItemID = @ItemID)
												UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit,
												LastCost = CASE WHEN @OUnitCost > 0 THEN @OUnitCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END,  
												CurrentCost = CASE WHEN @UnitCost = 0 THEN CurrentCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END, 
												CaseCost = CASE WHEN @CaseCost > 0 THEN @CaseCost ELSE @OCaseCost END,
												LastCaseCost = CASE WHEN @OCaseCost > 0 THEN @OCaseCost ELSE @CaseCost END,
												AvgCost = CASE WHEN @CaseCost > 0 THEN @ACost ELSE (CASE WHEN @UnitCost > 0 THEN @ACost END) END
												WHERE ItemID = @ItemID

												insert into xx_receiveditemslog(vpn,invoice_number,qty_received,date_received)
												  values (@VPN,@InvoiceNumber,@TotalUnit,@dateprocessed)
											END
									END
								ELSE						
									IF @UnitCost=0
										BEGIN
											--PRINT '@AInCase > 0  @QtyOrder > 0  @CaseOrder <= 0 @UnitCost=0'
											UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit
											WHERE ItemID = @ItemID
										END
									ELSE
										BEGIN
											--PRINT '@AInCase > 0  @QtyOrder > 0  @CaseOrder <= 0 @UnitCost<>0'
											UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit,
											LastCost = CASE WHEN @OUnitCost > 0 THEN @OUnitCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END,  
											CurrentCost = CASE WHEN @UnitCost = 0 THEN CurrentCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END, 
											AvgCost = @ACost  
											WHERE ItemID = @ItemID
										END
							ELSE
									
								IF @CaseCost=0
									BEGIN
										--PRINT 'AInCase > 0   @QtyOrder <= 0 CaseCost=0'
										UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit
										WHERE ItemID = @ItemID
									END
								ELSE
									BEGIN
										--PRINT 'AInCase > 0   @QtyOrder <= 0 CaseCost<>0'
										SELECT @OCaseCost = (SELECT CaseCost FROM Iteminfo WHERE ItemID = @ItemID)
										UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit,
										LastCost = CASE WHEN @OUnitCost > 0 THEN @OUnitCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END,  
										CurrentCost = CASE WHEN @UnitCost = 0 THEN CurrentCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END, 
										CaseCost = CASE WHEN @CaseCost > 0 THEN @CaseCost ELSE @OCaseCost END,
										LastCaseCost = CASE WHEN @OCaseCost > 0 THEN @OCaseCost ELSE @CaseCost END,
										AvgCost = CASE WHEN ABS(@TotalCost) > 0 THEN @ACost END
										WHERE ItemID = @ItemID

										insert into xx_receiveditemslog(vpn,invoice_number,qty_received,date_received)
												  values (@VPN,@InvoiceNumber,@TotalUnit,@dateprocessed)
									END
							END
					ELSE
						
						
						IF @UnitCost=0
							BEGIN
								--PRINT '@UnitCost=0 @AInCase = 0'
								UPDATE ItemInfo SET QtyOnHand = QtyOnHand + @TotalUnit
								WHERE ItemID = @ItemID
							END
						ELSE
							BEGIN
								--PRINT '@UnitCost<>0 @AInCase = 0'
								UPDATE ItemInfo SET  QtyOnHand = QtyOnHand + @TotalUnit,
								LastCost = CASE WHEN @OUnitCost > 0 THEN @OUnitCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END,  
								CurrentCost = CASE WHEN @UnitCost = 0 THEN CurrentCost ELSE ABS(@TotalCost)/ABS(@TotalUnit) END, 
								AvgCost = @ACost 
								WHERE ItemID = @ItemID
							END
				END
			ELSE	--Ingredient
				BEGIN
					IF (SELECT SUM(TotalUnit) FROM PurchaseOrderDetail WHERE ItemID = 0 AND ScanCode = @ScanCode AND TotalUnit > 0 ) > 0 
						SELECT @ACost = ABS((SELECT SUM(TotalCost) / SUM(TotalUnit) FROM PurchaseOrderDetail 
						WHERE ItemID = 0 AND ScanCode = @ScanCode AND TotalUnit > 0 ))
					ELSE
						SELECT @ACost = 0
						
					IF @AInCase > 0 
						UPDATE IngredientInfo SET QtyOnHand = QtyOnHand + @TotalUnit , AvgCost = @ACost , 
						LastCost = @CaseCost / @AInCase  
						WHERE IScanCode = @ScanCode
					ELSE
						UPDATE IngredientInfo SET  QtyOnHand = QtyOnHand + @TotalUnit, 
						AvgCost = @ACost, LastCost = @CostPerUnit  
						WHERE IScanCode = @ScanCode

					DECLARE @IngCost VARCHAR(25), @ID INT, @ISC VARCHAR(25), @CC MONEY
					SELECT @IngCost = (SELECT cvalue FROM posconfig WHERE cname = 'ingredientsetupcost')

					IF upper(@IngCost)='AVG COST'
						DECLARE AL CURSOR FOR
						SELECT ItemID, IScanCode, (AvgCost * (QtyUsed + (QtyUsed * Yield) / 100)) /UUnits 
						FROM ItemIngredient a, IngredientInfo b, Measurement c
						WHERE a.IScanid = b.IScanCode AND b.MeasurementID = c.MeasurementID 
						AND b.IScanCode = @ScanCode AND UUnits > 0
					ELSE
						DECLARE AL CURSOR FOR
						SELECT ItemID, IScanCode,(LastCost * (QtyUsed + (QtyUsed * Yield) / 100)) / UUnits 
						FROM ItemIngredient a, IngredientInfo b, Measurement c
						WHERE a.IScanid = b.IScanCode AND b.MeasurementID = c.MeasurementID 
						AND b.IScanCode = @ScanCode AND UUnits > 0

					OPEN AL
					FETCH NEXT FROM AL INTO @ID, @ISC, @CC
					WHILE (@@FETCH_STATUS = 0)
						BEGIN
							UPDATE ItemIngredient SET ICost = @CC WHERE ItemID = @ID AND IScanID = @ISC
							FETCH NEXT FROM AL INTO @ID, @ISC, @CC
						END
					CLOSE AL
					DEALLOCATE AL			
			END
			
			FETCH NEXT FROM PO_RECEIVE_CUR INTO @ItemID, @ScanCode, @ItemOrIng, @ItemName, @VPN, 
			@AInCase, @CaseOrder, @CaseCost, @QtyOrder, @TotalUnit, @TotalCost, @OUnitCost, @UnitCost

			SET @rcvd_count = @rcvd_count + 1;
		END
		
	
			
	CLOSE PO_RECEIVE_CUR
	DEALLOCATE PO_RECEIVE_CUR	

	UPDATE xx_runningstatus set sts = 1, rcvd_count = @rcvd_count;
END

