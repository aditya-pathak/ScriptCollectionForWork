--Lists all the tables and their columns, data types and foreign keys.
SELECT 
    o.object_id,
    table_name = CONCAT(SCHEMA_NAME(o.schema_id), N'.', o.name),
    c.column_id,
    column_name = c.name,
    data_type = CONCAT(t.name, psl.precision_scale_len, ni.identity_info, ni.nullability),
    fkx.fk_constraint
FROM
    sys.objects o WITH (NOLOCK)
    JOIN sys.columns c WITH (NOLOCK)
        ON o.object_id = c.object_id
    JOIN sys.types t WITH (NOLOCK)
        ON c.user_type_id = t.user_type_id
    CROSS APPLY ( VALUES (CASE 
        WHEN c.user_type_id IN (34,35,36,40,48,52,56,58,59,60,61,62,98,99,104,122,127,128,129,130,189,241,256) THEN N''
        WHEN c.user_type_id IN (106,108) THEN N'(' + CONVERT(NVARCHAR(10), c.precision) + ',' + CONVERT(NVARCHAR(10), c.scale) + N')'
        WHEN c.user_type_id IN (41,42,43) THEN N'(' + CONVERT(NVARCHAR(10), c.scale) + N')'
        WHEN c.user_type_id IN (165,167,173,175) THEN N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CONVERT(NVARCHAR(10), c.max_length) END + N')'
        WHEN c.user_type_id IN (231,239) THEN N'(' + CASE WHEN c.max_length = -1 THEN N'max' ELSE CONVERT(NVARCHAR(10), c.max_length / 2) END + N')'
    END) ) psl (precision_scale_len)
    CROSS APPLY ( VALUES (
        CASE WHEN c.is_nullable = 1 THEN N' null' ELSE N' not null' END,
        CASE WHEN c.is_identity = 0 THEN N'' ELSE (SELECT CONCAT(N' identity(', CONVERT(INT, ic.seed_value), N',', CONVERT(INT, ic.increment_value), N')') FROM sys.identity_columns ic WHERE c.object_id = ic.object_id AND c.column_id = ic.column_id) END
        ) ) ni (nullability, identity_info)
    OUTER APPLY (
        SELECT 
            fk_constraint = CONCAT(N'CONSTRAINT ', fk.name, 
                                    N' FOREIGN KEY REFFERENCES ', SCHEMA_NAME(CONVERT(INT, OBJECTPROPERTYEX(fkc.referenced_object_id, 'SchemaId'))), N'.', OBJECT_NAME(fkc.referenced_object_id), N' (', rc.name, N')',
                                    N' {ON UPDATE: ', fk.update_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS, N'} {ON DELETE: ', fk.delete_referential_action_desc COLLATE SQL_Latin1_General_CP1_CI_AS, N'} {IS TRUSTED: ', CASE WHEN fk.is_not_trusted = 1 THEN N'NO' ELSE N'YES' END, N'}'
                                    )
        FROM
            sys.foreign_key_columns fkc WITH (NOLOCK)
            JOIN sys.foreign_keys fk WITH (NOLOCK)
                ON fkc.constraint_object_id = fk.object_id
            JOIN sys.columns rc WITH (NOLOCK)
                ON fkc.referenced_object_id = rc.object_id
                AND fkc.referenced_column_id = rc.column_id
        WHERE 
            c.object_id = fkc.parent_object_id
            AND c.column_id = fkc.parent_column_id
            AND fk.is_disabled = 0
        ) fkx
WHERE 
    o.type = 'U';
