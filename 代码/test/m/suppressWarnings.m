function C = suppressWarnings()
status = warning('off');
C = onCleanup(@() warning(status));
end
