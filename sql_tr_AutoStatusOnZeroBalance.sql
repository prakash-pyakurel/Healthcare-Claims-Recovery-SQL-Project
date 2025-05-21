CREATE OR ALTER TRIGGER tr_AutoStatusOnZeroBalance
ON ACPR
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO STATUS (ACPR_REF_ID, STATUS, STATUS_DATE, UPDATED_BY, COMMENTS)
    SELECT 
        i.ACPR_REF_ID,
        'CLOSED',
        GETDATE(),
        'trigger_system',
        'Auto-closed because net amount was set to zero'
    FROM inserted i
    JOIN deleted d ON i.ACPR_REF_ID = d.ACPR_REF_ID
    WHERE i.ACPR_NET_AMT = 0 AND d.ACPR_NET_AMT <> 0;
END;