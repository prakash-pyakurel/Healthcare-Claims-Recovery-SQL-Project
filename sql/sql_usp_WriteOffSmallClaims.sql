CREATE OR ALTER PROCEDURE usp_WriteOffSmallClaims
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Today DATE = CAST(GETDATE() AS DATE);

    IF OBJECT_ID('tempdb..#EligibleWriteOffs') IS NOT NULL
        DROP TABLE #EligibleWriteOffs;

    SELECT A.ACPR_REF_ID, A.ACPR_SUB_TYPE, A.ACPR_NET_AMT, A.ACPR_CREATE_DT
    INTO #EligibleWriteOffs
    FROM ACPR A
    WHERE A.ACPR_STS = 'A'
        AND A.ACPR_NET_AMT < 100
        AND DATEDIFF(DAY, A.ACPR_CREATE_DT, @Today) > 300
        AND (
            A.ACPR_TYPE = 'MO' OR (A.ACPR_TYPE = 'MR' AND A.EXCD_ID IN ('THS', 'VXD', 'PHI'))
        )
        AND NOT EXISTS (
            SELECT 1 FROM STATUS S WHERE S.ACPR_REF_ID = A.ACPR_REF_ID AND S.STATUS = 'WRITE-OFF'
        );

    INSERT INTO ACRH (ACPR_REF_ID, ACPR_SUB_TYPE, ACRH_EVENT_TYPE, ACRH_MCTR_RSN, ACRH_AMT, EVENT_DT)
    SELECT E.ACPR_REF_ID, E.ACPR_SUB_TYPE, 'W', 'SWOF', E.ACPR_NET_AMT, @Today FROM #EligibleWriteOffs E;

    UPDATE A SET A.ACPR_NET_AMT = 0
    FROM ACPR A INNER JOIN #EligibleWriteOffs E ON A.ACPR_REF_ID = E.ACPR_REF_ID;

    INSERT INTO STATUS (ACPR_REF_ID, STATUS, STATUS_DATE, UPDATED_BY, COMMENTS)
    SELECT E.ACPR_REF_ID, 'WRITE-OFF', @Today, 'system_proc', 'Auto-write-off due to small balance'
    FROM #EligibleWriteOffs E;

    PRINT 'Write-off process completed.';
END;