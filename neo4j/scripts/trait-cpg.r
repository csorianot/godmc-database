ao <- TwoSampleMR::available_outcomes()
library(dplyr)
source("utils.r")
load("../data/trait_id_master.rdata")


traits <- subset(ao, id %in% subset(master, !is.na(id_06))$id_mrb & access != "developer") %>% as_data_frame

instdat <- "/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/data/snps_gwas.rdata"

load(instdat)

gkeep <- subset(a, id.exposure %in% master$id_06)
inst <- data_frame(
	snp = gkeep$id,
	rsid = gkeep$SNP,
	effect_allele=gkeep$effect_allele.exposure,
	other_allele=gkeep$other_allele.exposure,
	beta=gkeep$beta.exposure,
	se=gkeep$se.exposure,
	pval=gkeep$pval.exposure,
	trait=gkeep$trait,
	mr_keep=gkeep$mr_keep.exposure,
	units=gkeep$units.exposure_dat,
	id=gkeep$id.exposure,
	samplesize=gkeep$samplesize.exposure,
	ncase=gkeep$ncase.exposure,
	ncontrol=gkeep$ncontrol.exposure
)

names(inst) <- modify_rel_headers_for_neo4j(inst, "snp", "Snp", "id", "Trait")


names(traits)[names(traits) == "id"] <- "id_mrb"
temp <- data_frame(id=master$id_06, id_mrb=master$id_mrb)
traits <- inner_join(traits, temp)
names(traits)[names(traits) == "trait"] <- "name"
names(traits) <- modify_node_headers_for_neo4j(traits, "id", "Trait")


write_out(traits, "../data/trait-cpg/trait", header=TRUE)
write_out(inst, "../data/trait-cpg/inst", header=TRUE)



###################

sigcodes <- "/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/results/mrbase_sig_codes.rdata"



topdat <- "/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/results/mrbase_tophits_full.rdata"

sigcodes <- "/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/results/mrbase_sig_codes.rdata"

library(magrittr)

load(sigcodes)
codes <- codes %$% data_frame(code, decision, pass=msig)
load(topdat)
names(res)[names(res) == "b"] <- "beta"
res <- subset(res, id.exposure %in% traits$`TraitId:ID(Trait)`, select=-c(id.outcome, exposure))
res$code <- paste(res$id.exposure, res$outcome)
res <- merge(res, codes, by="code", all.x=TRUE)
res$decision[is.na(res$decision)] <- 0
res$pass[is.na(res$pass)] <- FALSE
res <- subset(res, select=-c(code))
names(res) <- modify_rel_headers_for_neo4j(res, "id.exposure", "Trait", "outcome", "Cpg")

names(plei)[names(plei) == "b"] <- "beta"
plei <- subset(plei, id.exposure %in% traits$`TraitId:ID(Trait)`, select=-c(id.outcome, exposure))
names(plei) <- modify_rel_headers_for_neo4j(plei, "id.exposure", "Trait", "outcome", "Cpg")

names(het)[names(het) == "b"] <- "beta"
het <- subset(het, id.exposure %in% traits$`TraitId:ID(Trait)`, select=-c(id.outcome, exposure))
names(het) <- modify_rel_headers_for_neo4j(het, "id.exposure", "Trait", "outcome", "Cpg")

write_out(res, "../data/trait-cpg/res", header=TRUE)
write_out(het, "../data/trait-cpg/het", header=TRUE)
write_out(plei, "../data/trait-cpg/plei", header=TRUE)


####

nom <- list.files("/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/results/out/") %>% grep("gwas", ., value=TRUE) %>% paste0("/mnt/storage/private/mrcieu/research/GODMC_Analysis/godmc_phase2_analysis/06_mr-gwas-cpg/results/out/", .)

load(nom[2])
names(res)[names(res) == "b"] <- "beta"
res <- subset(res, id.exposure %in% traits$`TraitId:ID(Trait)`, select=-c(id.outcome, exposure))
stopifnot(nrow(res) > 0)
names(res) <- modify_rel_headers_for_neo4j(res, "id.exposure", "Trait", "outcome", "Cpg")
write.table(res[0,], file="../data/trait-cpg/full_header.csv", row=FALSE, col.names=TRUE, sep=",")

j <- 1
g <- gzfile("../data/trait-cpg/full.csv.gz", "w")

for(i in 1:length(nom))
{
	message(i, " of ", length(nom))
	load(nom[i])
	if(res[1,1] %in% traits$`TraitId:ID(Trait)`)
	{
		names(res)[names(res) == "b"] <- "beta"
		res <- subset(res, id.exposure %in% traits$`TraitId:ID(Trait)`, select=-c(id.outcome, exposure))
		names(res) <- modify_rel_headers_for_neo4j(res, "id.exposure", "Trait", "outcome", "Cpg")
		write.table(res, g, row=FALSE, col.names=FALSE, sep=",")
	} else {
		message("Skip")
	}
}

close(g)


