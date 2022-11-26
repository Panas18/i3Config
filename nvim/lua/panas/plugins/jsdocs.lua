local status, jsDoc = pcall(require, "vim-jsdoc")

if not status then
  print("JS doc not installed")
  return
end

jsDoc.setup()

