function run(msg, matches)
text = io.popen(" sudo service redis-server start"):read('*all')
  return "ردیس با موفقیت آن شد." 
end
return {
  patterns = {
    '^[#/!]redis$'
  },
  run = run,
  moderated = true
}
