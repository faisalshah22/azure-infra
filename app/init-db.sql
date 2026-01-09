IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[quotes]') AND type in (N'U'))
BEGIN
    CREATE TABLE quotes (
        id INT IDENTITY(1,1) PRIMARY KEY,
        quote NVARCHAR(MAX) NOT NULL
    );
    
    INSERT INTO quotes (quote) VALUES
    ('The only way to do great work is to love what you do.'),
    ('Innovation distinguishes between a leader and a follower.'),
    ('Life is what happens to you while you''re busy making other plans.'),
    ('The future belongs to those who believe in the beauty of their dreams.'),
    ('It is during our darkest moments that we must focus to see the light.');
END

