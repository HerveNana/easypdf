-- Add file_path column to documents table
ALTER TABLE public.documents
ADD COLUMN IF NOT EXISTS file_path TEXT;

-- Add comment to explain the column
COMMENT ON COLUMN public.documents.file_path IS 'Local file path for imported documents stored on device';