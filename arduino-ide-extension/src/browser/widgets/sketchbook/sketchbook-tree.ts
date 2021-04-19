import { inject, injectable } from 'inversify';
import { LabelProvider } from '@theia/core/lib/browser/label-provider';
import { Command } from '@theia/core/lib/common/command';
import { TreeNode, CompositeTreeNode } from '@theia/core/lib/browser/tree';
import { DirNode, FileStatNode, FileTree } from '@theia/filesystem/lib/browser/file-tree';
import { Sketch, SketchesService } from '../../../common/protocol';
import { FileStat } from '@theia/filesystem/lib/common/files';
import { SketchbookCommands } from './sketchbook-commands';

@injectable()
export class SketchbookTree extends FileTree {

    @inject(LabelProvider)
    protected readonly labelProvider: LabelProvider;

    @inject(SketchesService)
    protected readonly sketchesService: SketchesService;

    async resolveChildren(parent: CompositeTreeNode): Promise<TreeNode[]> {
        if (!FileStatNode.is(parent)) {
            return super.resolveChildren(parent);
        }
        const { root } = this;
        if (!root) {
            return [];
        }
        if (!SketchbookTree.RootNode.is(root)) {
            return [];
        }
        const children = await Promise.all((await super.resolveChildren(parent)).map(node => this.maybeDecorateNode(node, root.showAllFiles)));
        if (SketchbookTree.RootNode.is(parent)) {
            return children.filter(DirNode.is).filter(node => ['libraries', 'hardware'].indexOf(this.labelProvider.getName(node)) === -1);
        }
        if (SketchbookTree.SketchDirNode.is(parent)) {
            return children.filter(FileStatNode.is);
        }
        return children.filter(DirNode.is);
    }

    private async maybeDecorateNode(node: TreeNode, showAllFiles: boolean): Promise<TreeNode> {
        if (DirNode.is(node)) {
            const sketch = await this.sketchesService.maybeLoadSketch(node.uri.toString());
            if (sketch) {
                Object.assign(node, { sketch, commands: [SketchbookCommands.OPEN, SketchbookCommands.OPEN_NEW_WINDOW] });
                if (!showAllFiles) {
                    delete (node as any).expanded;
                }
                return node;
            }
        }
        return node;
    }

}

export namespace SketchbookTree {

    export interface RootNode extends DirNode {
        readonly showAllFiles: boolean;
    }
    export namespace RootNode {

        export function is(node: TreeNode & Partial<RootNode>): node is RootNode {
            return typeof node.showAllFiles === 'boolean';
        }

        export function create(fileStat: FileStat, showAllFiles: boolean): RootNode {
            return Object.assign(DirNode.createRoot(fileStat), { showAllFiles, visible: false });
        }

    }

    export interface SketchDirNode extends DirNode {
        readonly sketch: Sketch;
        readonly commands?: Command[];
    }
    export namespace SketchDirNode {

        export function is(node: TreeNode & Partial<SketchDirNode> | undefined): node is SketchDirNode {
            return !!node && Sketch.is(node.sketch) && DirNode.is(node);
        }

    }

}
