context('basic functionality')

test_that('fill_pdf',{

  tempFile <- tempfile(fileext = '.pdf')

  # pdfFile <- system.file('testForm.pdf',package = 'staplr')
  pdfFile <- system.file('testForm.pdf',package = 'staplr')

  fields <- get_fields(pdfFile)

  fields$TextField1$value <- 'this is text'
  fields$TextField2$value <- 'more text with some \\ / paranthesis () ('
  fields$RadioGroup$value <- 2
  fields$checkBox$value <- 'Yes'
  fields$`List Box`$value <- 'Entry1'
  # fields$TextFieldPage2$value = 'some special chars �, �, �, �, �'
  fields$node1$value <- 'SimilarName'
  fields$betweenHierarch$value <- 'between hierarchies'
  fields$hierarchy.node2$value <- 'first hiearchy node 2'
  fields$hierarchy2.child.node1$value <- 'second hierarchy child 1 node 1'
  fields$hierarchy2.child2.node2$value <- 'second hierarchy child 2 node 2'

  fields$`(weird) paranthesis`$value <- 'paranthesis is weird'
  fields$`weird #C3#91 characters`$value <- 'characters are weird'

  set_fields(pdfFile,tempFile,fields)
  pdfText = pdftools::pdf_text(tempFile)

  # ensure that the resulting file is filled with the correct text
  # some have [\\s]+ in them to ensure they are read correctly even if they are
  # divided between multiple lines
  expect_true(grepl('this is text', pdfText[1]))
  expect_true(grepl('more text with some \\ / paranthesis () (', pdfText[1],fixed = TRUE))
  expect_true(grepl('Entry1', pdfText[1]))
  # expect_true(grepl('�, �, �, �, �', pdftools::pdf_text(tempFile)[2],fixed = TRUE))
  # default texts seems to be erased by other pdftk functions. not sure why.
  # expect_true(grepl('default[\\s]+node1', pdftools::pdf_text(tempFile)[1],perl = TRUE))
  expect_true(grepl('second[\\s]+hierarchy[\\s]+child[\\s]+1[\\s]+node[\\s]+1', pdfText[1],perl = TRUE))
  expect_true(grepl('first[\\s]+hiearchy[\\s]+node[\\s]+2', pdfText[1],perl = TRUE))
  expect_true(grepl('between[\\s]+hierarchies', pdfText[1],perl = TRUE))
  expect_true(grepl('A similarly named non hierarchical field[\\s\\S]+?SimilarName', pdfText[1],perl = TRUE))
  expect_true(grepl('paranthesis', pdfText[1],perl = TRUE))
  expect_true(grepl('characters', pdfText[1],perl = TRUE))

  testOutput = tempfile(fileext = '.pdf')
  idenfity_form_fields(pdfFile, testOutput)
  pdfText = pdftools::pdf_text(testOutput)
  expect_true(grepl('TextField1', pdfText[1],perl = TRUE))
  expect_true(grepl('TextFieldPage2', pdfText[2],perl = TRUE))
  expect_true(grepl('TextFieldPage3', pdfText[3],perl = TRUE))
})



test_that('remove_pages',{
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  tempFile <- tempfile(fileext = '.pdf')

  remove_pages(rmpages = 1, pdfFile, tempFile)
  # ensure that the page is removed so the new page 1 is the old page 2
  expect_true(pdftools::pdf_text(pdfFile)[2] == pdftools::pdf_text(tempFile)[1])
})

test_that('select_pages',{
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  tempFile <- tempfile(fileext = '.pdf')

  select_pages(selpages = 2, pdfFile, tempFile)
  # ensure that the page is removed so the new page 1 is the old page 2
  expect_true(pdftools::pdf_text(pdfFile)[2] == pdftools::pdf_text(tempFile)[1])
})

test_that('rotate',{
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  tempFile <- tempfile(fileext = '.pdf')
  rotate_pages(c(1,2), 90, pdfFile, tempFile)

  # check the dimensions of the rotated pdf files to see if its rotated
  newDims <- dim(pdftools::pdf_render_page(tempFile,1))
  oldDims <- dim(pdftools::pdf_render_page(pdfFile,1))
  expect_equal(newDims[2],oldDims[3])
  expect_equal(newDims[3],oldDims[2])


  tempFile <- tempfile(fileext = '.pdf')
  rotate_pdf(90, pdfFile, tempFile)

  # check the dimensions of the rotated pdf files to see if its rotated
  newDims <- dim(pdftools::pdf_render_page(tempFile,1))
  oldDims <- dim(pdftools::pdf_render_page(pdfFile,1))
  expect_equal(newDims[2],oldDims[3])
  expect_equal(newDims[3],oldDims[2])
})


test_that('split',{
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  pdfFileInfo <- pdftools::pdf_info(pdfFile)
  tempDir <- tempfile()
  dir.create(tempDir)
  split_pdf(pdfFile,tempDir,prefix = 'p')

  splitFiles <- list.files(tempDir,pattern = '.pdf',full.names = TRUE)

  # expect as many pages as the number of pages in the original file
  expect_equal(length(splitFiles), pdfFileInfo$pages)

  # compare the second page of the original file with the second page created
  # this also checks if the prefix works and the number of trailing zeroes
  expect_equal(pdftools::pdf_text(pdfFile)[2],pdftools::pdf_text(file.path(tempDir,'p0002.pdf')))

  tempDir <- tempfile()
  dir.create(tempDir)
  split_from(pg_num = 1,pdfFile,tempDir,prefix = 'p')
  # compare the text of the original file with the resulting files
  expect_equal(pdftools::pdf_text(pdfFile)[1],pdftools::pdf_text(file.path(tempDir,'p1.pdf')))
  expect_equal(pdftools::pdf_text(pdfFile)[2],pdftools::pdf_text(file.path(tempDir,'p2.pdf'))[1])
  expect_equal(pdftools::pdf_text(pdfFile)[3],pdftools::pdf_text(file.path(tempDir,'p2.pdf'))[2])


  # multi split points
  tempDir <- tempfile()
  dir.create(tempDir)
  split_from(pg_num = c(1,2),pdfFile,tempDir,prefix = 'p')

  expect_equal(pdftools::pdf_text(pdfFile)[1],pdftools::pdf_text(file.path(tempDir,'p1.pdf')))
  expect_equal(pdftools::pdf_text(pdfFile)[2],pdftools::pdf_text(file.path(tempDir,'p2.pdf')))
  expect_equal(pdftools::pdf_text(pdfFile)[3],pdftools::pdf_text(file.path(tempDir,'p3.pdf')))

})


test_that('staple',{
  # create individual pdfs first
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  pdfFileInfo <- pdftools::pdf_info(pdfFile)
  tempDir <- tempfile()
  dir.create(tempDir)
  split_pdf(pdfFile,tempDir)

  # re-create the original file
  tempFile <- tempfile(fileext = '.pdf')
  staple_pdf(input_directory = tempDir,output_filepath = tempFile)
  # compare with original file
  expect_identical(pdftools::pdf_text(pdfFile) ,pdftools::pdf_text(tempFile))

  # staple by filename
  tempFile <- tempfile(fileext = '.pdf')
  files <- list.files(tempDir,pattern = '.pdf',full.names = TRUE)
  staple_pdf(input_files = files[c(1,2)],output_filepath = tempFile)
  expect_identical(pdftools::pdf_text(pdfFile)[1:2] ,pdftools::pdf_text(tempFile))

})


test_that('overwrite',{
  # fill pdf
  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  tempFile = tempfile(fileext = '.pdf')
  file.copy(pdfFile,tempFile)

  fields <- get_fields(tempFile)
  fields$TextField1$value <- 'this is text'
  set_fields(pdfFile,tempFile,fields,overwrite = TRUE)
  expect_true(grepl('this is text', pdftools::pdf_text(tempFile)[1]))
  expect_error(set_fields(pdfFile,tempFile,fields,overwrite = FALSE),'already exists')


  oldSecondPage = pdftools::pdf_text(tempFile)[2]
  # remove pages)
  remove_pages(rmpages = 1, tempFile, tempFile,overwrite = TRUE)
  # ensure that the page is removed so the new page 1 is the old page 2
  expect_true(oldSecondPage == pdftools::pdf_text(tempFile)[1])

  oldDims <- dim(pdftools::pdf_render_page(tempFile,1))

  rotate_pages(c(1), 90, tempFile, tempFile,overwrite = TRUE)
  # check the dimensions of the rotated pdf files to see if its rotated
  newDims <- dim(pdftools::pdf_render_page(tempFile,1))

  expect_equal(newDims[2],oldDims[3])
  expect_equal(newDims[3],oldDims[2])

  oldDims <- dim(pdftools::pdf_render_page(tempFile,2))
  rotate_pdf(90,tempFile,tempFile,overwrite = TRUE)
  newDims <- dim(pdftools::pdf_render_page(tempFile,2))
  expect_equal(newDims[2],oldDims[3])
  expect_equal(newDims[3],oldDims[2])


  # ensure that the page is removed so the new page 1 is the old page 2
  oldPage2 = pdftools::pdf_text(tempFile)[2]
  select_pages(selpages = 2, tempFile, tempFile,overwrite = TRUE)
  expect_true(oldPage2 == pdftools::pdf_text(tempFile)[1])

  pdfFile <- system.file('testForm.pdf',package = 'staplr')
  file.copy(pdfFile,tempFile,overwrite = TRUE)
  tempDir = tempfile()
  dir.create(tempDir)
  split_from(tempFile,pg_num = 2,output_directory = tempDir)
  expect_error(split_from(tempFile,pg_num = 2,output_directory = tempDir,overwrite = FALSE),'already exists')

  staple_pdf(input_directory = tempDir,output_filepath = tempFile)
  expect_error(staple_pdf(input_directory = tempDir,output_filepath = tempFile,overwrite = FALSE), 'already exists')


})
